//
//  AIExapenseTrackerApp.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

@main
struct AIExapenseTrackerApp: App {
    
    
    var body: some Scene {
        WindowGroup {
            
            RootView()
            #if os(macOS)
                .frame(minWidth:729, minHeight: 480)
            #endif
        }
        
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }
}
