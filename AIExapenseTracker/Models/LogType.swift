//
//  LogType.swift
//  AIExapenseTracker
//
//  Represents who owns an expense collection.
//  The rawValue IS the Firestore collection name — no extra mapping needed.
//  To add a new log type, just append a case here.
//

import Foundation

enum LogType: String, CaseIterable, Codable, Identifiable {
    case wife    = "logs"
    case husband = "husbandLogs"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wife:    return "Wife"
        case .husband: return "Husband"
        }
    }

    var icon: String {
        switch self {
        case .wife:    return "figure.dress.line.vertical.figure"
        case .husband: return "figure.stand"
        }
    }
}
