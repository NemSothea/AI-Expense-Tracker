//
//  IntroView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 25/9/25.
//

import SwiftUI

// MARK: - Model
struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

// MARK: - View
struct IntroductionView: View {
    
    var onLoginTapped: () -> Void
    
    @State private var selection: Int = 0
    
    private let pages: [OnboardingPage] = [
        .init(
            title: "Welcome to ExpenseAI",
            subtitle: "Track spending automatically with secure, private on-device insights.",
            systemImage: "chart.pie.fill"
        ),
        .init(
            title: "Smart Categorization",
            subtitle: "Your transactions get labeled by AI so you don’t have to.",
            systemImage: "list.bullet.rectangle.portrait.fill"
        ),
        .init(
            title: "Actionable Analytics",
            subtitle: "See trends, budgets, and forecasts to make better decisions.",
            systemImage: "chart.line.uptrend.xyaxis"
        ),
        .init(
            title: "Private by Design",
            subtitle: "You control your data. Create, delete, and manage securely.",
            systemImage: "lock.shield.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            // Subtle gradient background that adapts to Dark Mode
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.25),
                    Color.purple.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 16)
                
                // Logo / App mark
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.white)
                        .font(.system(size: 60))
                        .accessibilityHidden(true)
                        .padding()
                }
//                .background(Color.blue)
                .cornerRadius(10)
                .frame(width: 64,height: 64)
                
                Text("AI Expense Tracker")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 8)
                
                // Pager
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 18) {
                            // Feature illustration
                            Image(systemName: page.systemImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                                .shadow(radius: 4, y: 2)
                                .accessibilityHidden(true)
                            
                            Text(page.title)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                            
                            Text(page.subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(index)
                        .padding(.top, 8)
                    }
                }
                .tabViewStyle(.automatic)
                .pageTabViewStyle()
                .animation(.easeInOut, value: selection)
                .padding(.bottom, 8)
                
                // Controls
                HStack(spacing: 12) {
                    // Skip
                    Button {
                        onLoginTapped()
                    } label: {
                        Text("Skip")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    
                    // Next / Get Started
                    if selection < pages.count - 1 {
                        Button {
                            withAnimation(.easeInOut) { selection += 1 }
                        } label: {
                            HStack(spacing: 8) {
                                Text("Next")
                                    .font(.body.weight(.semibold))
                                Image(systemName: "arrow.right")
                                    .imageScale(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            onLoginTapped()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Get Started")
                                    .font(.body.weight(.semibold))
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 8)
        }
        .tint(.blue) // global accent
        .accessibilityElement(children: .contain)
    }
}

extension View {
    func pageTabViewStyle() -> some View {
        #if os(iOS)
        return self.tabViewStyle(.page(indexDisplayMode: .automatic))
        #else
        return self.tabViewStyle(.automatic)
        #endif
    }
}
