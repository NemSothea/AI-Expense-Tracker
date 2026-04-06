//
//  SyncManager.swift
//  AIExapenseTracker
//
//  The sync engine that keeps SwiftData (local) and Firestore (remote) in sync.
//
//  Flow:
//    Write path : User action → DatabaseManager → SwiftData (instant)
//                                                       ↓ (background)
//                                               SyncManager → Firestore
//
//    Read path  : Firestore snapshot → SyncManager → SwiftData → @Query → UI
//
//  One listener is maintained per LogType so all collections stay warm
//  simultaneously. When syncing pending changes, each local record carries
//  its `logType` which maps directly to the Firestore collection name.
//

import SwiftData
import FirebaseFirestore
import Combine

@MainActor
final class SyncManager: ObservableObject {

    static let shared = SyncManager()

    // Injected once at app startup via configure(with:)
    private var modelContainer: ModelContainer?
    // One listener per LogType (keyed by collection name = LogType.rawValue)
    private var listeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Bootstrap

    func configure(with container: ModelContainer) {
        guard modelContainer == nil else { return }   // idempotent
        modelContainer = container
        migrateEmptyLogTypes()
        setupNetworkObserver()
        setupFirestoreListeners()
    }

    // MARK: - Schema Migration
    // Records created before the logType field was added may have logType set to
    // NULL in the CoreData store (not ""), which CoreData predicates cannot match
    // with `== ""`. Fetch ALL records and validate each one to be safe.
    private func migrateEmptyLogTypes() {
        guard let context = modelContainer?.mainContext else { return }
        guard let allRecords = try? context.fetch(FetchDescriptor<LocalExpenseLog>()),
              !allRecords.isEmpty else { return }

        let validLogTypes = Set(LogType.allCases.map { $0.rawValue })
        var dirty = false

        for record in allRecords {
            // Delete records with an empty id — they can never be synced to Firestore
            // and `collection.document("")` raises a fatal NSException.
            if record.id.isEmpty {
                context.delete(record)
                dirty = true
                continue
            }
            // Back-fill any logType that wasn't set during the schema migration.
            if !validLogTypes.contains(record.logType) {
                record.logType = LogType.wife.rawValue
                dirty = true
            }
        }

        if dirty { try? context.save() }
    }

    // MARK: - Network Observer

    private func setupNetworkObserver() {
        NetworkMonitor.shared.connectionPublisher
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncPendingChanges()
            }
            .store(in: &cancellables)
    }

    // MARK: - Firestore Listeners  (Remote → Local)
    // One listener per LogType so all collections stay in sync regardless of
    // which one the user is currently viewing.

    private func setupFirestoreListeners() {
        for logType in LogType.allCases {
            let listener = Firestore.firestore()
                .collection(logType.rawValue)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self, let snapshot, error == nil else { return }
                    self.handleSnapshot(snapshot, logType: logType)
                }
            listeners[logType.rawValue] = listener
        }
    }

    private func handleSnapshot(_ snapshot: QuerySnapshot, logType: LogType) {
        guard let context = modelContainer?.mainContext else { return }

        for change in snapshot.documentChanges {
            guard let remoteLog = try? change.document.data(as: ExpenseLog.self),
                  !remoteLog.id.isEmpty else { continue }   // skip malformed documents
            let remoteId = remoteLog.id
            let descriptor = FetchDescriptor<LocalExpenseLog>(
                predicate: #Predicate { $0.id == remoteId }
            )
            let existing = try? context.fetch(descriptor).first

            switch change.type {
            case .added, .modified:
                if let local = existing {
                    // Conflict resolution: keep local version if it is a pending
                    // upload AND was modified more recently than the remote write.
                    let remoteTimestamp: Date = .distantPast
                    if local.syncStatus == SyncStatus.pendingUpload.rawValue,
                       local.localModifiedAt > remoteTimestamp {
                        continue
                    }
                    local.applyRemoteUpdate(from: remoteLog)
                    local.logType = logType.rawValue
                } else {
                    let newLocal = LocalExpenseLog.from(remoteLog, syncStatus: .synced, logType: logType)
                    context.insert(newLocal)
                }

            case .removed:
                if let local = existing,
                   local.syncStatus != SyncStatus.pendingDelete.rawValue {
                    context.delete(local)
                }

            @unknown default:
                break
            }
        }

        try? context.save()
    }

    // MARK: - Push Pending Changes  (Local → Firestore)
    // Each local record stores its `logType` (= Firestore collection name),
    // so there is no need to guess which collection to target.

    func syncPendingChanges() {
        guard NetworkMonitor.shared.isConnected,
              let context = modelContainer?.mainContext else { return }

        let descriptor = FetchDescriptor<LocalExpenseLog>(
            predicate: #Predicate { $0.syncStatus != "synced" }
        )
        guard let pendingItems = try? context.fetch(descriptor),
              !pendingItems.isEmpty else { return }

        let validCollectionNames = Set(LogType.allCases.map { $0.rawValue })

        for item in pendingItems {
            // `collection.document("")` raises a fatal NSException that `try?` cannot
            // catch. Guard here before touching Firestore at all.
            guard !item.id.isEmpty else {
                context.delete(item)   // remove the corrupted record
                continue
            }

            let collectionName = validCollectionNames.contains(item.logType)
                ? item.logType
                : LogType.wife.rawValue
            let collection = Firestore.firestore().collection(collectionName)

            switch item.syncStatus {
            case SyncStatus.pendingUpload.rawValue:
                let log = item.toExpenseLog()
                try? collection.document(log.id).setData(from: log)
                item.syncStatus = SyncStatus.synced.rawValue

            case SyncStatus.pendingDelete.rawValue:
                let docId = item.id
                collection.document(docId).delete { [weak self] error in
                    guard error == nil else { return }
                    Task { @MainActor [weak self] in
                        self?.removeLocalRecord(id: docId)
                    }
                }

            default:
                break
            }
        }

        try? context.save()
    }

    // MARK: - Helpers

    private func removeLocalRecord(id: String) {
        guard let context = modelContainer?.mainContext else { return }
        let descriptor = FetchDescriptor<LocalExpenseLog>(
            predicate: #Predicate { $0.id == id }
        )
        if let local = try? context.fetch(descriptor).first {
            context.delete(local)
            try? context.save()
        }
    }

    // MARK: - Teardown

    func stop() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
        cancellables.removeAll()
    }
}
