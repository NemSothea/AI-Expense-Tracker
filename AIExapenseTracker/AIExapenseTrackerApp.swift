//
//  AIExapenseTrackerApp.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

@main
struct AIExapenseTrackerApp: App {

#if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
#else
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
#endif

    init() {
#if os(iOS)
        // Apply Battambang font to UINavigationBar on launch
        // (respects whatever language was last saved in AppStorage)
        LocalizationManager.shared.applyNavigationBarAppearance()
#endif
    }

    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
            #if os(macOS)
                .frame(minWidth:729, minHeight: 480)
            #endif
        }
        
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }
}
