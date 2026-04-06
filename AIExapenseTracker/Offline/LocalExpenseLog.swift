//
//  LocalExpenseLog.swift
//  AIExapenseTracker
//

import SwiftData
import Foundation

// Sync state of a local record
enum SyncStatus: String, Codable {
    case synced         = "synced"
    case pendingUpload  = "pendingUpload"   // created/edited locally, not yet in Firestore
    case pendingDelete  = "pendingDelete"   // deleted locally, not yet removed from Firestore
}

@Model
final class LocalExpenseLog {

    @Attribute(.unique) var id: String
    var name: String
    var category: String
    var amount: Double
    var currency: String
    var date: Date
    var notes: String?
    var syncStatus: String          // stores SyncStatus.rawValue
    var localModifiedAt: Date
    /// The Firestore collection this record belongs to (= LogType.rawValue).
    /// Defaults to "logs" so existing records migrate without data loss.
    var logType: String = LogType.wife.rawValue

    init(
        id: String,
        name: String,
        category: String,
        amount: Double,
        currency: String = "USD",
        date: Date,
        notes: String? = nil,
        syncStatus: SyncStatus = .pendingUpload,
        logType: LogType = .wife
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.currency = currency
        self.date = date
        self.notes = notes
        self.syncStatus = syncStatus.rawValue
        self.localModifiedAt = Date()
        self.logType = logType.rawValue
    }

    // MARK: - Conversion helpers

    func toExpenseLog() -> ExpenseLog {
        ExpenseLog(id: id, name: name, category: category,
                   amount: amount, currency: currency, date: date, notes: notes)
    }

    func applyRemoteUpdate(from log: ExpenseLog) {
        name = log.name
        category = log.category
        amount = log.amount
        currency = log.currency
        date = log.date
        notes = log.notes
        syncStatus = SyncStatus.synced.rawValue
        localModifiedAt = Date()
    }

    static func from(
        _ log: ExpenseLog,
        syncStatus: SyncStatus = .pendingUpload,
        logType: LogType = .wife
    ) -> LocalExpenseLog {
        LocalExpenseLog(
            id: log.id,
            name: log.name,
            category: log.category,
            amount: log.amount,
            currency: log.currency,
            date: log.date,
            notes: log.notes,
            syncStatus: syncStatus,
            logType: logType
        )
    }
}
