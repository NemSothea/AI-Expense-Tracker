//
//  logFormViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 16/12/24.
//

import Foundation
import Observation

@Observable
class FormViewModel  {
    var logToEdit: ExpenseLog?
    let db = DatabaseManager.shared
    
    var name = ""
    var amount: Double = 0
    var amountText: String = ""
    var category = Category.utilities
    var date: Date = Date()
    var notes: String = ""

    var isSaveButtonDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init(logToEdit: ExpenseLog? = nil) {
        self.logToEdit = logToEdit
        if let logToEdit {
            self.name = logToEdit.name
            self.amount = logToEdit.amount
            self.category = logToEdit.categoryEnum
            self.date = logToEdit.date
            self.notes = logToEdit.notes ?? ""
            numberFormatter.currencyCode = logToEdit.currency
            self.amountText = numberFormatter.string(from: NSNumber(value: logToEdit.amount)) ?? "\(logToEdit.amount)"
        }
    }

    /// Called when the amount field loses focus. Parses the raw integer string,
    /// stores it as `amount`, then reformats `amountText` for display.
    func commitAmount() {
        let cleaned = amountText.filter { $0.isNumber || $0 == "." }
        let parsed = Double(cleaned) ?? 0
        amount = parsed
        amountText = numberFormatter.string(from: NSNumber(value: parsed)) ?? "\(parsed)"
    }

    @MainActor func save() {
        // Commit any un-confirmed amount before saving
        commitAmount()

        var log: ExpenseLog
        if let logToEdit {
            log = logToEdit
        } else {
            log = ExpenseLog(id: UUID().uuidString, name: "Unknown", category: "Unknown", amount: 0, date: .now)
        }

        log.name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        log.category = self.category.rawValue
        log.amount = self.amount
        log.date = self.date
        log.notes = self.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self.notes
        
        if self.logToEdit == nil {
            db.add(log: log)
        }else {
            db.update(log: log)
        }

        
    }
    @MainActor func delete(log: ExpenseLog) {
        db.delete(log: log)
    }
    
}

