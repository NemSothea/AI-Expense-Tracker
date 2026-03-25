//
//  VisionAddReceiptConfirmationViewModel.swift
//  AIExapenseTracker
//

import Foundation
import Observation

@Observable
class VisionAddReceiptConfirmationViewModel {

    let db = DatabaseManager.shared

    private let originalLogs: [ExpenseLog]
    private let originalDate: Date
    private let originalCurrency: String

    var expenseLogs: [ExpenseLog]
    var date: Date
    var currencyCode: String {
        didSet { numberFormatter.currencyCode = currencyCode }
    }

    var isEdited: Bool {
        currencyCode != originalCurrency
            || date != originalDate
            || expenseLogs != originalLogs
    }

    let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.isLenient = true
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()

    init(scanResult: VisionScanResult) {
        let logs     = scanResult.expenseLogs
        let currency = scanResult.receipt.currency ?? "USD"
        let date     = scanResult.receipt.date ?? .now

        self.originalLogs     = logs
        self.originalDate     = date
        self.originalCurrency = currency

        self.expenseLogs  = logs
        self.date         = date
        self.currencyCode = currency
        self.numberFormatter.currencyCode = currency
    }

    @MainActor func save() {
        expenseLogs.forEach { log in
            var updated = log
            updated.date     = date
            updated.currency = currencyCode
            db.add(log: updated)
        }
    }

    func resetChanges() {
        expenseLogs  = originalLogs
        date         = originalDate
        currencyCode = originalCurrency
    }
}
