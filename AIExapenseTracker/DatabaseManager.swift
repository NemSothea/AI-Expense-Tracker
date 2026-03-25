//
//  DataBaseManager.swift
//  AIExapenseTracker
//
//  All write operations (add / update / delete) now target SwiftData first so
//  they complete instantly, even with no network.  SyncManager picks up the
//  pending records and pushes them to Firestore in the background.
//
//  The Firestore CollectionReference is still exposed so that SyncManager and
//  any legacy read-paths that have not yet migrated can use it directly.
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

    // Keep the collection reference so SyncManager can use it
    private(set) lazy var logsCollection: CollectionReference = {
        Firestore.firestore().collection("logs")
    }()

    // MARK: - Local-first writes

    @MainActor func add(log: ExpenseLog) {
        guard let context = modelContext else { return }
        let local = LocalExpenseLog.from(log, syncStatus: .pendingUpload)
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
            // Mark as pending delete so it disappears from UI immediately
            // and SyncManager will remove it from Firestore when online.
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
