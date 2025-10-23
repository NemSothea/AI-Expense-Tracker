//
//  logListViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import Foundation
import Observation

@Observable
class LogListViewModel {
    
    private let expenseService = ExpenseService.shared
    
    var expenses: [Expense] = []
    var isLoading = false
    var error: String?
    
    // Filtering and sorting
    var sortType = SortType.date
    var sortOrder = SortOrder.descending
    var selectedCategories = Set<Category>()
    
    // UI State
    var isLogFormPresented = false
    var expenseToEdit: Expense?
    
    // Pagination
    private var currentPage = 0
    private let pageSize = 20
    var hasMorePages = true
    
    @MainActor
    func loadExpenses(isRefreshing: Bool = false) async {
        if isRefreshing {
            currentPage = 0
            hasMorePages = true
            expenses.removeAll()
        }
        
        guard !isLoading && hasMorePages else { return }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await expenseService.getExpenses(
                page: currentPage,
                size: pageSize
            )
            
            await MainActor.run {
                if isRefreshing {
                    self.expenses = response.content
                } else {
                    self.expenses.append(contentsOf: response.content)
                }
                self.hasMorePages = !response.last
                self.currentPage += 1
            }
        } catch {
            await MainActor.run {
                self.error = (error as? NetworkError)?.localizedDescription ?? "Failed to load expenses"
            }
        }
    }
    
    @MainActor
    func createExpense(name: String, amount: Double, category: Category, date: Date) async -> Bool {
        guard let user = AuthManager.shared.currentUser else {
            error = "Please login again"
            return false
        }
        
        // Convert SwiftUI Category to backend category ID
        // You'll need to map your Category enum to backend category IDs
        let categoryId = mapCategoryToBackendId(category)
        
        let request = ExpenseRequest(
            userId: user.id,
            categoryId: categoryId,
            amount: amount,
            description: name,
            expenseDate: formatDateForBackend(date)
        )
        
        do {
            _ = try await expenseService.createExpense(request)
            // Refresh the list
            await loadExpenses(isRefreshing: true)
            return true
        } catch {
            self.error = (error as? NetworkError)?.localizedDescription ?? "Failed to create expense"
            return false
        }
    }
    
    @MainActor
    func updateExpense(expense: Expense, name: String, amount: Double, category: Category, date: Date) async -> Bool {
        guard let user = AuthManager.shared.currentUser else {
            error = "Please login again"
            return false
        }
        
        let categoryId = mapCategoryToBackendId(category)
        
        let request = ExpenseRequest(
            userId: user.id,
            categoryId: categoryId,
            amount: amount,
            description: name,
            expenseDate: formatDateForBackend(date)
        )
        
        do {
            _ = try await expenseService.updateExpense(expenseId: expense.id, request: request)
            // Refresh the list
            await loadExpenses(isRefreshing: true)
            return true
        } catch {
            self.error = (error as? NetworkError)?.localizedDescription ?? "Failed to update expense"
            return false
        }
    }
    
    @MainActor
    func deleteExpense(_ expense: Expense) async -> Bool {
        do {
            try await expenseService.deleteExpense(expenseId: expense.id)
            // Remove from local array
            if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses.remove(at: index)
            }
            return true
        } catch {
            self.error = (error as? NetworkError)?.localizedDescription ?? "Failed to delete expense"
            return false
        }
    }
    
    private func mapCategoryToBackendId(_ category: Category) -> Int {
        return category.backendId // Using the extension
    }
    
    private func formatDateForBackend(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Filtered and sorted expenses
    var filteredExpenses: [Expense] {
        var filtered = expenses
        
        // Apply category filter
        if !selectedCategories.isEmpty {
            filtered = filtered.filter { expense in
                selectedCategories.contains { category in
                    expense.category == category.rawValue
                }
            }
        }
        
        // Apply sorting
        filtered.sort { expense1, expense2 in
            switch sortType {
            case .date:
                let date1 = parseDate(expense1.expenseDate)
                let date2 = parseDate(expense2.expenseDate)
                return sortOrder == .ascending ? date1 < date2 : date1 > date2
            case .amount:
                return sortOrder == .ascending ? expense1.amount < expense2.amount : expense1.amount > expense2.amount
            case .name:
                return sortOrder == .ascending ? expense1.description < expense2.description : expense1.description > expense2.description
            }
        }
        
        return filtered
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }
}
