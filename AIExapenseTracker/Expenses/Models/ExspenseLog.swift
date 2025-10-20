//
//  Category.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import Foundation


struct ExspenseLog : Codable, Identifiable, Equatable {
    
    var id  : String
    var name : String
    var category : String
    var amount : Double
    var currency : String
    var date : Date
    
    
    var categoryEnum : Category {
        Category(rawValue: category) ?? .utilities
    }
    
    init(id: String, name: String, category: String, amount: Double, currency: String = "USD", date: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.currency = currency
        self.date = date
    }

}

extension ExspenseLog {
    
    var dateText : String {
        Utils.dateFormatter.string(from: date)
    }
    var amountText : String {
        Utils.numberFormatter.currencySymbol = currency
        return Utils.numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
