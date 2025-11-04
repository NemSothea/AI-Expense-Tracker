//
//  FunctionResponse.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 21/10/25.
//

import Foundation

typealias AddExpenseLogConfirmationCallback = @Sendable (Bool, AddExpenseLogViewProperties) async -> Void

enum UserConfirmation {
    case pending, confirmed, cancelled
}

struct AddExpenseLogViewProperties : Sendable {
    let log: ExpenseLog
    let messageID: UUID?
    let userConfirmation: UserConfirmation
    let confirmationCallback: AddExpenseLogConfirmationCallback?
}

struct AIAssistantResponse : Sendable {
    let text: String
    let type: AIAssistantResponseFunctionType
}

enum AIAssistantResponseFunctionType : Sendable {
    case addExpenseLog(AddExpenseLogViewProperties)
    case listExpenses([ExpenseLog])
    case visualizeExpenses(ChartType, [Option])
    case contentText
}
