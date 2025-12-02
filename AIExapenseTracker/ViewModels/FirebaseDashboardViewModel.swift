//
//  FirebaseDashboardViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 2/12/25.
//
import SwiftUI
import FirebaseFirestore

// MARK: - Firebase Dashboard ViewModel
class FirebaseDashboardViewModel: ObservableObject {
    
    @Published var expenseLogs: [ExpenseLog] = []
    @Published var isLoading = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    private var listener: ListenerRegistration?
    
    var primaryCurrency: String {
        // Get the most common currency from logs, default to USD
        let currencies = expenseLogs.map { $0.currency }
        let currencyCounts = Dictionary(grouping: currencies, by: { $0 })
            .mapValues { $0.count }
        
        if let mostCommon = currencyCounts.max(by: { $0.value < $1.value })?.key {
            return mostCommon
        }
        return "USD"
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
            return TopCategory(
                categoryId: categoryName,
                name: categoryName,
                totalAmount: total,
                pctOfTotal: pct
            )
        }
        .sorted { $0.totalAmount > $1.totalAmount }
    }
    
    var recentExpenses: [RecentExpense] {
        expenseLogs
            .sorted { $0.date > $1.date }
            .map { log in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: log.date)
                
                return RecentExpense(
                    id: log.id,
                    description: log.name,
                    amount: log.amount,
                    currency: log.currency,
                    category: log.category,
                    expenseDate: dateString
                )
            }
    }
    
    func setupListener() {
        isLoading = true
        
        listener = DatabaseManager.shared.logsCollection
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.expenseLogs = []
                        return
                    }
                    
                    self.expenseLogs = documents.compactMap { document in
                        try? document.data(as: ExpenseLog.self)
                    }
                    
                    print("📊 Updated expense logs: \(self.expenseLogs.count) items")
                }
            }
    }
    
    func fetchExpenseLogs() {
        isLoading = true
        
        DatabaseManager.shared.logsCollection
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.expenseLogs = []
                        return
                    }
                    
                    self.expenseLogs = documents.compactMap { document in
                        try? document.data(as: ExpenseLog.self)
                    }
                }
            }
    }
    
    func removeListener() {
        listener?.remove()
        listener = nil
    }
    
    deinit {
        removeListener()
    }
}
