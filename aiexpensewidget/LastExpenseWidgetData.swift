//
//  LastExpenseWidgetData.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 16/12/25.
//


import Foundation

struct LastExpenseWidgetData: Codable {
    
    let name        : String
    let date        : Date
    let amount      : Double
    let currency    : String
}

enum LastExpenseWidgetStore {
    static let appGroupID = "group.kh.com.kosign.widgets"
    static let key = "last_expense_widget_data"
}
