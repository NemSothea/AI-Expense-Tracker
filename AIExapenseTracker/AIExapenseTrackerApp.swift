//
//  AIExapenseTrackerApp.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI
import SwiftData

@main
struct AIExapenseTrackerApp: App {

#if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
#else
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
#endif

    // Single ModelContainer shared across the whole app
    let modelContainer: ModelContainer = {
        let schema = Schema([LocalExpenseLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
#if os(iOS)
        LocalizationManager.shared.applyNavigationBarAppearance()
#endif
    }

    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .modelContainer(modelContainer)
                .environment(NetworkMonitor.shared)
                .environment(AppSettings.shared)
                .task {
                    // Wire the sync engine to the container once the scene is ready
                    await MainActor.run {
                        SyncManager.shared.configure(with: modelContainer)
                        DatabaseManager.shared.configure(with: modelContainer.mainContext)
                    }
                }
            #if os(macOS)
                .frame(minWidth: 729, minHeight: 480)
            #endif
        }

        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }
}
