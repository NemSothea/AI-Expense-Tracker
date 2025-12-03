//
//  AnimatedDashboardHomeView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import SwiftUI
import Charts
import FirebaseFirestore

struct AnimatedDashboardHomeView: View {
    
    @StateObject private var vm = FirebaseDashboardViewModel()
    
    @State private var isRefreshing = false
    @State private var hasAppeared = false

    
    // Chart colors
    private let chartColors: [Color] = [
        .blue, .green, .orange, .purple, .red,
        .yellow, .pink, .teal, .indigo, .mint
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if vm.isLoading {
                        loadingView
                    } else if !vm.expenseLogs.isEmpty {
                        animatedContentView()
                    } else {
                        emptyStateView
                    }
                }
                .padding()
                
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await refreshData()
            }
        }

        .onAppear {
            if hasAppeared {
                vm.fetchExpenseLogs()
            }
            hasAppeared = true
        }
        .onDisappear {
            vm.removeListener()
        }
        .task {
            if vm.expenseLogs.isEmpty {
                vm.setupListener()
            }
        }
        .alert("Error", isPresented: $vm.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage)
        }
    }
    
    // MARK: - Loading Animation
    private var loadingView: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 100)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                        .shimmering()
                }
            }
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .shimmering()
        }
    }
    
    
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding()
            
            Text("No Expenses Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first expense to see your spending dashboard")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // You can add a button to navigate to add expense here
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Animated Content
    private func animatedContentView() -> some View {
        Group {
            // Summary Cards with staggered animation
            summaryCardsView()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            
            // Chart with fade-in animation
            chartSection()
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            // Recent expenses with slide-up animation
            recentExpensesSection()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Summary Cards
    private func summaryCardsView() -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnimatedSummaryCard(
                title: "Total Spent",
                value: vm.totalExpenses,
                format: .currency(code: vm.primaryCurrency),
                icon: "dollarsign.circle.fill",
                color: .blue,
                delay: 0.1
            )
            
            AnimatedSummaryCard(
                title: "Avg Transaction",
                value: vm.averageTransaction,
                format: .currency(code: vm.primaryCurrency),
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                delay: 0.2
            )
            
            if let topCategory = vm.topCategories.first {
                AnimatedSummaryCard(
                    title: "Top Category",
                    value: topCategory.totalAmount,
                    format: .currency(code: vm.primaryCurrency),
                    subtitle: topCategory.name,
                    icon: "crown.fill",
                    color: .orange,
                    delay: 0.3
                )
            } else {
                AnimatedSummaryCard(
                    title: "Top Category",
                    value: 0,
                    format: .currency(code: vm.primaryCurrency),
                    subtitle: "No data",
                    icon: "crown.fill",
                    color: .orange,
                    delay: 0.3
                )
            }
        }
    }
    
    // MARK: - Chart Section
    private func chartSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .opacity(vm.topCategories.isEmpty ? 0.5 : 1)
            
            if vm.topCategories.isEmpty {
                emptyChartView
            } else {
                AnimatedPieChartView(topCategories: vm.topCategories, colors: chartColors)
                
                // Animated Category Legend
                animatedCategoryLegendView()
            }
        }
        .padding()
        .background(Color.random().opacity(0.1))
        .cornerRadius(12)
    }
    
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No spending data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    

       
    
    private func animatedCategoryLegendView() -> some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(vm.topCategories.enumerated()), id: \.offset) { index, category in
                HStack {
                    Circle()
                        .fill(chartColors[index % chartColors.count])
                        .frame(width: 12, height: 12)
                        .scaleEffect(category.totalAmount > 0 ? 1 : 0)
                    
                    Text(category.name)
                        .font(.caption)
                        .lineLimit(1)
                        .opacity(category.totalAmount > 0 ? 1 : 0)
                        .offset(x: category.totalAmount > 0 ? 0 : -20)
                    
                    Spacer()
                    
                    Text(category.totalAmount, format: .currency(code: vm.primaryCurrency))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    
                    Text("(\(Int(category.pctOfTotal))%)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(0.5 + Double(index) * 0.1),
                    value: category.totalAmount
                )
            }
        }
    }
    
    // MARK: - Recent Expenses
    private func recentExpensesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                
                Spacer()
            
            }
            
            if vm.recentExpenses.isEmpty {
                Text("No recent expenses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(vm.recentExpenses.prefix(5).enumerated()), id: \.offset) { index, expense in
                        AnimatedRecentExpenseRow(expense: expense, delay: Double(index) * 0.1)
                    }
                }
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Refresh Handler
    private func refreshData() async {
        isRefreshing = true
        vm.fetchExpenseLogs()
        try? await Task.sleep(nanoseconds: 500_000_000) // Small delay
        isRefreshing = false
    }
}


// MARK: - Animated Recent Expense Row (Updated)
struct AnimatedRecentExpenseRow: View {
    
    let expense: RecentExpense
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.categoryEnum.systemNameIcon)
                .font(.callout)
                .foregroundColor(expense.categoryEnum.color)
                .frame(width: 32)
                .scaleEffect(isVisible ? 1 : 0)
                .rotationEffect(.degrees(isVisible ? 0 : -180))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description)
                    .font(.subheadline)
                    .lineLimit(1)
                    .opacity(isVisible ? 1 : 0)
                    .offset(x: isVisible ? 0 : -20)
                
                Text(expense.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(isVisible ? 1 : 0)
                    .offset(x: isVisible ? 0 : -10)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .opacity(isVisible ? 1 : 0)
                    .offset(x: isVisible ? 0 : 20)
                
                Text(expense.expenseDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(isVisible ? 1 : 0)
                    .offset(x: isVisible ? 0 : 10)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}



// MARK: - Shimmer Effect (keep existing)
extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(AnimatedMask(phase: phase).animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ))
            .onAppear { phase = 1 }
    }
}

struct AnimatedMask: GeometryEffect {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let amplitude: CGFloat = 30
        let translation = amplitude * sin(phase * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
extension Color {
    static func random() -> Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
  
    var isLight: Bool {
        // This is a simplified check - you might want to implement proper luminance calculation
        guard let components = UIColor(self).cgColor.components else { return false }
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness > 0.5
    }
    
}
