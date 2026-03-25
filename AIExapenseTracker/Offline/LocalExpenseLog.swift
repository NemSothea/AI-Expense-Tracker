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
    var syncStatus: String          // stores SyncStatus.rawValue
    var localModifiedAt: Date

    init(
        id: String,
        name: String,
        category: String,
        amount: Double,
        currency: String = "USD",
        date: Date,
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.currency = currency
        self.date = date
        self.syncStatus = syncStatus.rawValue
        self.localModifiedAt = Date()
    }

    // MARK: - Conversion helpers

    func toExpenseLog() -> ExpenseLog {
        ExpenseLog(id: id, name: name, category: category,
                   amount: amount, currency: currency, date: date)
    }

    func applyRemoteUpdate(from log: ExpenseLog) {
        name = log.name
        category = log.category
        amount = log.amount
        currency = log.currency
        date = log.date
        syncStatus = SyncStatus.synced.rawValue
        localModifiedAt = Date()
    }

    static func from(_ log: ExpenseLog, syncStatus: SyncStatus = .pendingUpload) -> LocalExpenseLog {
        LocalExpenseLog(
            id: log.id,
            name: log.name,
            category: log.category,
            amount: log.amount,
            currency: log.currency,
            date: log.date,
            syncStatus: syncStatus
        )
    }
}
