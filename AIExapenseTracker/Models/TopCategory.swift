//
//  TopCategory.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 2/12/25.
//
import SwiftUI

// MARK: - Supporting Models for Dashboard Display
struct TopCategory: Identifiable {
    var id: String { categoryId }
    let categoryId: String
    let name: String
    let totalAmount: Double
    let pctOfTotal: Double
}

struct RecentExpense: Identifiable {
    let id: String
    let description: String
    let amount: Double
    let currency: String
    let category: String
    let expenseDate: String
    
    var categoryEnum: Category {
        Category(rawValue: category) ?? .utilities
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(amount)"
    }
}
