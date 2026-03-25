//
//  AppDelegate.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import Foundation
import Firebase
import FirebaseFirestore

#if os(macOS)
import Cocoa
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        setupFirebase()
    }
}

#else
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        setupFirebase()
        
        return true
        
    }
    
}


#endif

fileprivate func isPreviewRuntime() -> Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

fileprivate func setupFirebase() {
    FirebaseApp.configure()

    if isPreviewRuntime() {
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
    } else {
        // Enable persistent disk cache (200 MB) as a safety net for
        // any Firestore reads that bypass the SwiftData local store.
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: Int64(200 * 1024 * 1024) as NSNumber
        )
        Firestore.firestore().settings = settings
    }
}
