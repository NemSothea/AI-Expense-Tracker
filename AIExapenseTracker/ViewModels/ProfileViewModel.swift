//
//  ProfileViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007
//

import SwiftUI
@preconcurrency import FirebaseFirestore

// MARK: - Monthly Expense Summary

struct MonthlyExpenseSummary: Identifiable {
    var id: String { monthKey }

    let monthKey: String           // "2026-03"
    let displayMonth: String       // "March 2026"
    let totalsByCurrency: [String: Double]  // ["USD": 120.0, "KHR": 48000.0]

    var sortedCurrencies: [String] {
        // USD first, KHR second, rest alphabetical
        let priority = ["USD", "KHR"]
        let prioritised = priority.filter { totalsByCurrency[$0] != nil }
        let rest = totalsByCurrency.keys
            .filter { !priority.contains($0) }
            .sorted()
        return prioritised + rest
    }
}

// MARK: - Profile ViewModel

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var monthlySummaries: [MonthlyExpenseSummary] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false

    private var listener: ListenerRegistration?

    private let monthKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    func setupListener(for logType: LogType = AppSettings.shared.selectedLogType) {
        listener?.remove()   // tear down any existing listener before re-attaching
        isLoading = true
        listener = DatabaseManager.shared.collection(for: logType)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                Task { @MainActor in
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        return
                    }
                    let logs = snapshot?.documents.compactMap {
                        try? $0.data(as: ExpenseLog.self)
                    } ?? []
                    self.monthlySummaries = self.computeSummaries(from: logs)
                }
            }
    }

    func removeListener() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }

    // MARK: Private

    private func computeSummaries(from logs: [ExpenseLog]) -> [MonthlyExpenseSummary] {
        var grouped: [String: [ExpenseLog]] = [:]
        for log in logs {
            let key = monthKeyFormatter.string(from: log.date)
            grouped[key, default: []].append(log)
        }

        return grouped.map { monthKey, monthLogs -> MonthlyExpenseSummary in
            var totals: [String: Double] = [:]
            for log in monthLogs {
                totals[log.currency, default: 0] += log.amount
            }
            let date = monthKeyFormatter.date(from: monthKey) ?? Date()
            return MonthlyExpenseSummary(
                monthKey: monthKey,
                displayMonth: displayFormatter.string(from: date),
                totalsByCurrency: totals
            )
        }
        .sorted { $0.monthKey > $1.monthKey }
    }
}
