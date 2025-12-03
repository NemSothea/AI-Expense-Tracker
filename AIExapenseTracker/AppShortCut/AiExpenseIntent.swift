//
//  NavIntent.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 3/12/25.
//

import AppIntents
import SwiftUI


struct AiExpenseIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Open Ai Expense"
    
    static var description: IntentDescription? {
        IntentDescription(
            "Opens the AI Expense Tracker app",
            categoryName: "Navigation",
            searchKeywords: ["expense", "tracker", "ai", "open"]
        )
    }
    
    static var openAppWhenRun: Bool = true
    
    // For better macOS discoverability
    @MainActor
    static var suggestedInvocationPhrases: [LocalizedStringResource]? {
        [
            "Open AI Expense",
            "Show Expense Tracker",
            "Launch Expense App"
        ]
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // On macOS, we need to explicitly handle app activation
        #if os(macOS)
        // Bring app to foreground if it's already running
        NSApp.activate(ignoringOtherApps: true)
        
        // If you want to open a specific window:
        // NSApp.windows.first?.makeKeyAndOrderFront(nil)
        #endif
        
        return .result(dialog: "Opening AI Expense Tracker...")
    }
}
