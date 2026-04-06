//
//  AppSettings.swift
//  AIExapenseTracker
//
//  App-wide user preferences backed by UserDefaults.
//  Observed via Swift's @Observable macro — any view that reads
//  `selectedLogType` will automatically re-render when it changes.
//

import Foundation
import Observation

@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    private static let logTypeKey = "selectedLogType"

    var selectedLogType: LogType {
        didSet {
            UserDefaults.standard.set(selectedLogType.rawValue, forKey: Self.logTypeKey)
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.logTypeKey) ?? ""
        selectedLogType = LogType(rawValue: raw) ?? .wife
    }
}
