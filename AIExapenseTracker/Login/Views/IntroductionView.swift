//
//  IntroView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 25/9/25.
//

import SwiftUI


// MARK: - View
struct IntroductionView: View {
    
    var onLoginTapped: () -> Void
    
    @State private var selection: Int = 0
    @State private var isAnimating: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var currentPageIndex: Int = 0
    
    private let pages: [OnboardingPage] = [
        .init(
            title: "Welcome to ExpenseAI",
            subtitle: "Track spending automatically with secure, private on-device insights.",
            systemImage: "chart.pie.fill",
            color: .blue
        ),
        .init(
            title: "Smart Categorization",
            subtitle: "Your transactions get labeled by AI so you don't have to.",
            systemImage: "list.bullet.rectangle.portrait.fill",
            color: .green
        ),
        .init(
            title: "Actionable Analytics",
            subtitle: "See trends, budgets, and forecasts to make better decisions.",
            systemImage: "chart.line.uptrend.xyaxis",
            color: .orange
        ),
        .init(
            title: "Private by Design",
            subtitle: "You control your data. Create, delete, and manage securely.",
            systemImage: "lock.shield.fill",
            color: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            // Dynamic gradient background that changes with page
            LinearGradient(
                colors: [
                    pages[selection].color.opacity(0.25),
                    pages[selection].color.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: selection)
            
            // Animated background shapes
            BackgroundShapes(color: pages[selection].color)
                .opacity(0.3)
            
            VStack(spacing: 0) {
                Spacer(minLength: 16)
                
                // Logo with animation
                HStack {
                    Image("AI Expense")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .shadow(radius: 10)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isAnimating)
                }
                .padding()

                Text("AI Expense Tracker")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 8)
                    .scaleEffect(isAnimating ? 1 : 0.9)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isAnimating)
                
                // Enhanced Pager with custom indicators
                ZStack {
                    TabView(selection: $selection) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            OnboardingPageView(
                                page: page,
                                isActive: selection == index,
                                dragOffset: dragOffset
                            )
                            .tag(index)
                        }
                    }
                    .pageTabViewStyle()
                    .animation(.easeInOut(duration: 0.4), value: selection)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                if value.translation.width < -threshold && selection < pages.count - 1 {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        selection += 1
                                    }
                                } else if value.translation.width > threshold && selection > 0 {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        selection -= 1
                                    }
                                }
                                withAnimation(.easeOut) {
                                    dragOffset = 0
                                }
                            }
                    )
                    
                    // Custom page indicators
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Capsule()
                                    .fill(selection == index ? pages[selection].color : Color.gray.opacity(0.4))
                                    .frame(width: selection == index ? 24 : 8, height: 8)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selection)
                            }
                        }
                        .padding(.bottom, 60)
                    }
                }
                .padding(.bottom, 8)
                
                // Enhanced Controls
                HStack(spacing: 12) {
                    // Skip button with fade animation
                    if selection < pages.count - 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onLoginTapped()
                            }
                        } label: {
                            Text("Skip")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                    
                    // Next / Get Started button with dynamic content
                    Button {
                        if selection < pages.count - 1 {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selection += 1
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onLoginTapped()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(selection < pages.count - 1 ? "Next" : "Get Started")
                                .font(.body.weight(.semibold))
                            
                            Image(systemName: selection < pages.count - 1 ? "arrow.right" : "checkmark.circle.fill")
                                .imageScale(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(ProminentButtonStyle(color: pages[selection].color))
                    .scaleEffect(isAnimating ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isAnimating)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}


// MARK: - Custom Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .background(Color.systemGray6)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ProminentButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
    }
}

// MARK: - Extension
extension View {
    func pageTabViewStyle() -> some View {
        #if os(iOS)
        return self.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        return self.tabViewStyle(.automatic)
        #endif
    }
}
