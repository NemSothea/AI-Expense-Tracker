//
//  OrderAppShortcuts.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 3/12/25.
//


import Foundation
import AppIntents
import SwiftUI

struct OrderAppShortcuts: AppShortcutsProvider {
   
    static var appShortcuts: [AppShortcut] {
    
        AppShortcut(
            intent: AiExpenseIntent(),
            phrases: ["\(.applicationName)",
                      "Open \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Open AI Expense"),
            systemImageName: "sparkles"
        )
      
    }
    
    nonisolated(unsafe) static var shortcutTileColor: ShortcutTileColor = .blue
    
   
}
