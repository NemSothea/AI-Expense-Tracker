//
//  DataBaseManager.swift
//  AIExapenseTracker
//
//  All write operations (add / update / delete) now target SwiftData first so
//  they complete instantly, even with no network.  SyncManager picks up the
//  pending records and pushes them to Firestore in the background.
//
//  The active LogType is read from AppSettings so callers never need to pass
//  a collection name.  Each write also records the logType on the local record
//  so SyncManager knows which Firestore collection to target.
//

import Foundation
import SwiftData
import FirebaseFirestore

final class DatabaseManager: @unchecked Sendable {

    static let shared = DatabaseManager()

    private init() {}

    // Injected once at app startup (from AIExapenseTrackerApp)
    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        modelContext = context
    }

    // MARK: - Collection access

    /// Returns the Firestore CollectionReference for the given log type.
    /// The rawValue of LogType IS the collection name, so no mapping is needed.
    func collection(for logType: LogType) -> CollectionReference {
        Firestore.firestore().collection(logType.rawValue)
    }

    // MARK: - Local-first writes

    @MainActor func add(log: ExpenseLog) {
        guard let context = modelContext else { return }
        let logType = AppSettings.shared.selectedLogType
        let local = LocalExpenseLog.from(log, syncStatus: .pendingUpload, logType: logType)
        context.insert(local)
        save(context)
        SyncManager.shared.syncPendingChanges()
    }

    @MainActor func update(log: ExpenseLog) {
        guard let context = modelContext else { return }
        let id = log.id
        let descriptor = FetchDescriptor<LocalExpenseLog>(
            predicate: #Predicate { $0.id == id }
        )
        if let local = try? context.fetch(descriptor).first {
            local.name = log.name
            local.amount = log.amount
            local.category = log.category
            local.currency = log.currency
            local.date = log.date
            local.notes = log.notes
            local.syncStatus = SyncStatus.pendingUpload.rawValue
            local.localModifiedAt = Date()
            save(context)
            SyncManager.shared.syncPendingChanges()
        }
    }

    @MainActor func delete(log: ExpenseLog) {
        guard let context = modelContext else { return }
        let id = log.id
        let descriptor = FetchDescriptor<LocalExpenseLog>(
            predicate: #Predicate { $0.id == id }
        )
        if let local = try? context.fetch(descriptor).first {
            local.syncStatus = SyncStatus.pendingDelete.rawValue
            save(context)
            SyncManager.shared.syncPendingChanges()
        }
    }

    // MARK: - Private helpers

    private func save(_ context: ModelContext) {
        try? context.save()
    }
}
