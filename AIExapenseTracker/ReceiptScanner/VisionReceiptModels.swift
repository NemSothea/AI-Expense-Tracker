//
//  VisionReceiptModels.swift
//  AIExapenseTracker
//
//  On-device receipt models — no third-party AI API required.
//

import Foundation

extension Notification.Name {
    static let navigateToExpenseList = Notification.Name("navigateToExpenseList")
}

struct VisionReceipt {
    var storeName: String?
    var items: [VisionReceiptItem]
    var currency: String?
    var date: Date?
}

struct VisionReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double
    var price: Double
    var category: String
}

struct VisionScanResult: Identifiable {
    let id = UUID()
    let receipt: VisionReceipt

    /// Converts scanned items into ExpenseLog values ready for editing/saving.
    var expenseLogs: [ExpenseLog] {
        receipt.items.map { item in
            let name = item.quantity > 1
                ? "\(Int(item.quantity)) x \(item.name)"
                : item.name
            return ExpenseLog(
                id: UUID().uuidString,
                name: name,
                category: item.category,
                amount: item.price,
                currency: receipt.currency ?? "USD",
                date: receipt.date ?? .now
            )
        }
    }
}
