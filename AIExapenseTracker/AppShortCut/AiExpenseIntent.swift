//
//  NavIntent.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 3/12/25.
//


import Foundation
import AppIntents
import UIKit


struct AiExpenseIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Open Ai Expense"
    

    static var openAppInvocationPhrase: LocalizedStringResource = "Open Ai Expense"
  
    static var openAppWhenRun: Bool = true //This property is for directly open the app when click on shortapp
    

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
    
}
