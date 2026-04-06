//
//  Category.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import Foundation
import FirebaseFirestore

struct ExpenseLog : Codable, Identifiable, Equatable,Sendable {

    var id          : String
    var name        : String
    var category    : String
    var amount      : Double
    var currency    : String
    var date        : Date
    var notes       : String?


    var categoryEnum : Category {
        Category(rawValue: category) ?? .utilities
    }

    init(id: String, name: String, category: String, amount: Double, currency: String = "USD", date: Date, notes: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.currency = currency
        self.date = date
        self.notes = notes
    }

}

extension ExpenseLog {
    
    var dateText : String {
        Utils.dateFormatter.string(from: date)
    }
    var amountText : String {
        Utils.numberFormatter.currencySymbol = currency
        return Utils.numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    var amountListText : String {
        Utils.numberListFormatter.currencySymbol = currency
        Utils.numberListFormatter.currencyCode = currency
        return Utils.numberListFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
