//
//  DashboardResponse.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import Foundation

// MARK: - Dashboard Response
struct DashboardResponse: Codable, Sendable {
    let totals: TotalExpenses
    let topCategories: [TopCategory]
    let recentExpenses: [RecentExpense]
    
    enum CodingKeys: String, CodingKey {
        case totals
        case topCategories = "top_categories"
        case recentExpenses = "recent_expenses"
    }
}

struct TotalExpenses: Codable, Sendable {
    let totalExpenses: Double
    let averageExpense: Double
    
    enum CodingKeys: String, CodingKey {
        case totalExpenses = "total_expenses"
        case averageExpense = "average_expense"
    }
}

struct TopCategory: Codable, Sendable, Identifiable {
    let categoryId: Int
    let name: String
    let totalAmount: Double
    let txCount: Int
    let pctOfTotal: Double
    
    var id: Int { categoryId }
    
    enum CodingKeys: String, CodingKey {
        case categoryId
        case name
        case totalAmount
        case txCount
        case pctOfTotal
    }
}

struct RecentExpense: Codable, Sendable, Identifiable {
    let id: Int
    let expenseDate: String
    let category: String
    let description: String
    let amount: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case expenseDate
        case category
        case description
        case amount
    }
}
