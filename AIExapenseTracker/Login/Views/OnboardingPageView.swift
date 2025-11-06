//
//  OnboardingPageView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 6/11/25.
//
import SwiftUI

// MARK: - Subviews
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    let dragOffset: CGFloat
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon with color transition
            Image(systemName: page.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(page.color)
                .scaleEffect(isActive ? 1 : 0.8)
                .opacity(isActive ? 1 : 0.5)
                .rotationEffect(.degrees(Double(dragOffset) * 0.1))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isActive)
                .animation(.easeOut(duration: 0.2), value: dragOffset)
                .accessibilityHidden(true)
            
            // Text content with staggered animation
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .scaleEffect(isActive ? 1 : 0.9)
                    .opacity(isActive ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isActive)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .scaleEffect(isActive ? 1 : 0.9)
                    .opacity(isActive ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isActive)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: dragOffset)
        .padding(.top, 8)
    }
}
