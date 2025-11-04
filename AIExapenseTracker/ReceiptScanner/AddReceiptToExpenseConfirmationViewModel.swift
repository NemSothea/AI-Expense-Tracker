//
//  AddReceiptToExpenseConfirmationViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 21/10/25.
//

import AIReceiptScanner
import Observation
import Foundation

@Observable
class AddReceiptToExpenseConfirmationViewModel {
    
    let scanResult: SuccessScanResult
    let scanResultExpenseLogs: [ExpenseLog]
    
    var date: Date
    var currencyCode: String {
        willSet {
            self.numberFormatter.currencyCode = newValue
        }
    }
    var expenseLogs: [ExpenseLog]
    var isEdited: Bool {
        !(scanResult.receipt.date == date && expenseLogs == scanResultExpenseLogs)
    }
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.isLenient = true
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    init(scanResult: SuccessScanResult) {
        self.scanResult = scanResult
        self.scanResultExpenseLogs = scanResult.receipt.expenseLogs
        self.expenseLogs = self.scanResultExpenseLogs
        self.date = scanResult.receipt.date ?? .now
        self.currencyCode = scanResult.receipt.currency ?? "USD"
        self.numberFormatter.currencyCode = self.currencyCode
    }
    
    func save() async throws {
        // Get current user
        guard let user = await AuthManager.shared.currentUser else {
            throw NetworkError.unauthorized
        }
        
        // Save each expense log
        for log in expenseLogs {
            var updatedLog = log
            updatedLog.date = self.date
            updatedLog.currency = self.currencyCode
            
            let request = ExpenseRequest(from: updatedLog, userId: user.id)
            _ = try await ExpenseService.shared.createExpense(request)
        }
    }
    
    func resetChanges() {
        self.expenseLogs = self.scanResultExpenseLogs
        self.date = scanResult.receipt.date ?? .now
        self.currencyCode = scanResult.receipt.currency ?? "USD"
    }
    
}

