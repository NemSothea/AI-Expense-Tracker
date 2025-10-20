//
//  logFormViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 16/12/24.
//

import Foundation
import Observation

@Observable
class FormViewModel {
    var expenseToEdit: Expense?
    private let logListVM: LogListViewModel
    
    var name = ""
    var amount: Double = 0
    var category = Category.utilities
    var date: Date = Date()
    
    
    var isSaveButtonDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0
    }
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.isLenient = true
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    init(expenseToEdit: Expense? = nil, logListVM: LogListViewModel) {
        self.expenseToEdit = expenseToEdit
        self.logListVM = logListVM
        
        if let expenseToEdit {
            self.name = expenseToEdit.description
            self.amount = expenseToEdit.amount
            // Use reverse mapping
            self.category = Category.fromBackendName(expenseToEdit.category)
            // Parse date string to Date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.date(from: expenseToEdit.expenseDate) ?? Date()
        }
    }
    
    
    
    @MainActor
    func save() async -> Bool {
        if expenseToEdit == nil {
            // Create new expense
            return await logListVM.createExpense(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                category: category,
                date: date
            )
        } else {
            // Update existing expense
            guard let expenseToEdit = expenseToEdit else { return false }
            return await logListVM.updateExpense(
                expense: expenseToEdit,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                category: category,
                date: date
            )
        }
    }
}
