//
//  ExpenseModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

// MARK: - Expense Model
struct Expense: Codable, Identifiable, Sendable {
    let id: Int
    let category: String
    let categoryId: Int
    let description: String
    let expenseDate: String
    let amount: Double
    let userId: Int?
}

// MARK: - Paginated Response
struct PaginatedResponse<T: Codable>: Codable, Sendable {
    let content: [T]
    let totalPages: Int
    let totalElements: Int
    let last: Bool
    let first: Bool
    let size: Int
    let number: Int
    let empty: Bool
}

// MARK: - Create/Update Expense Request
struct ExpenseRequest: Codable, Sendable {
    let userId: Int
    let categoryId: Int
    let amount: Double
    let description: String
    let expenseDate: String
}

// MARK: - Category Model
struct ExpenseCategory: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let enabled: Bool
}

// MARK: - Dashboard Summary
struct DashboardSummary: Codable, Sendable {
    let totalExpenses: Double
    let expensesByCategory: [CategoryExpense]
    let recentExpenses: [Expense]
}

struct CategoryExpense: Codable, Sendable {
    let category: String
    let totalAmount: Double
    let percentage: Double
}
