//
//  FirebaseDashboardViewModel.swift
//  AIExapenseTracker
//
//  Data is now sourced from SwiftData (@Query in the view) and pushed here
//  via updateExpenseLogs(_:).  No direct Firestore connection needed.
//

import SwiftUI

class FirebaseDashboardViewModel: ObservableObject {

    @Published var expenseLogs: [ExpenseLog] = []

    // Called by AnimatedDashboardHomeView whenever @Query produces new results
    func updateExpenseLogs(_ logs: [ExpenseLog]) {
        expenseLogs = logs
    }

    // MARK: - Derived stats

    var primaryCurrency: String {
        let currencies = expenseLogs.map { $0.currency }
        let counts = Dictionary(grouping: currencies, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "USD"
    }

    var totalExpenses: Double {
        expenseLogs.reduce(0) { $0 + $1.amount }
    }

    var averageTransaction: Double {
        guard !expenseLogs.isEmpty else { return 0 }
        return totalExpenses / Double(expenseLogs.count)
    }

    var topCategories: [TopCategory] {
        let grouped = Dictionary(grouping: expenseLogs, by: { $0.category })
        return grouped.map { categoryName, logs in
            let total = logs.reduce(0) { $0 + $1.amount }
            let pct = totalExpenses > 0 ? (total / totalExpenses) * 100 : 0
            return TopCategory(categoryId: categoryName, name: categoryName,
                               totalAmount: total, pctOfTotal: pct)
        }
        .sorted { $0.totalAmount > $1.totalAmount }
    }

    var recentExpenses: [RecentExpense] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return expenseLogs
            .sorted { $0.date > $1.date }
            .map { log in
                RecentExpense(
                    id: log.id,
                    description: log.name,
                    amount: log.amount,
                    currency: log.currency,
                    category: log.category,
                    expenseDate: formatter.string(from: log.date)
                )
            }
    }
}
