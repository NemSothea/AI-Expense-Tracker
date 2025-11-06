//
//  OnboardingPage.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 6/11/25.
//
import SwiftUI

// MARK: - Model
struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
}
