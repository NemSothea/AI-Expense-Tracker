//
//  Untitled.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 25/10/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    static var systemBackground: Color {
#if os(macOS)
        return Color(NSColor.windowBackgroundColor)
#else
        return Color(UIColor.systemBackground)
#endif
    }
    
    static var systemGray6: Color {
#if os(macOS)
        return Color(NSColor.controlBackgroundColor)
#else
        return Color(UIColor.systemGray6)
#endif
    }
}
