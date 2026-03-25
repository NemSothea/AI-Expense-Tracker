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

import SwiftData
import FirebaseFirestore
import Combine

@MainActor
final class SyncManager: ObservableObject {

    static let shared = SyncManager()

    // Injected once at app startup via configure(with:)
    private var modelContainer: ModelContainer?
    private var firestoreListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Bootstrap

    func configure(with container: ModelContainer) {
        guard modelContainer == nil else { return }   // idempotent
        modelContainer = container
        setupNetworkObserver()
        setupFirestoreListener()
    }

    // MARK: - Network Observer
    // When the device comes back online, flush any locally queued changes.

    private func setupNetworkObserver() {
        NetworkMonitor.shared.connectionPublisher
            .filter { $0 }   // only when transitioning to connected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncPendingChanges()
            }
            .store(in: &cancellables)
    }

    // MARK: - Firestore Listener  (Remote → Local)
    // Uses addSnapshotListener so we receive incremental document changes,
    // including the full set on first launch which seeds the local database.

    private func setupFirestoreListener() {
        firestoreListener = Firestore.firestore()
            .collection("logs")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot, error == nil else { return }
                self.handleSnapshot(snapshot)
            }
    }

    private func handleSnapshot(_ snapshot: QuerySnapshot) {
        guard let context = modelContainer?.mainContext else { return }

        for change in snapshot.documentChanges {
            guard let remoteLog = try? change.document.data(as: ExpenseLog.self) else { continue }
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
                        // Local wins – do not overwrite
                        continue
                    }
                    local.applyRemoteUpdate(from: remoteLog)
                } else {
                    let newLocal = LocalExpenseLog.from(remoteLog, syncStatus: .synced)
                    context.insert(newLocal)
                }

            case .removed:
                // Only delete locally if we did not initiate the deletion
                // (pendingDelete items will be cleaned up after Firestore confirms).
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
    // Called on network reconnection and after every local write when online.

    func syncPendingChanges() {
        guard NetworkMonitor.shared.isConnected,
              let context = modelContainer?.mainContext else { return }

        let descriptor = FetchDescriptor<LocalExpenseLog>(
            predicate: #Predicate { $0.syncStatus != "synced" }
        )
        guard let pendingItems = try? context.fetch(descriptor),
              !pendingItems.isEmpty else { return }

        let collection = Firestore.firestore().collection("logs")

        for item in pendingItems {
            switch item.syncStatus {

            case SyncStatus.pendingUpload.rawValue:
                let log = item.toExpenseLog()
                // Fire-and-forget; Firestore listener will echo back and mark synced
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
        firestoreListener?.remove()
        firestoreListener = nil
        cancellables.removeAll()
    }
}
