//
//  AnimatedDashboardHomeView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import SwiftUI
import Charts

struct AnimatedDashboardHomeView: View {
    @State private var vm = DashboardViewModel()
    @State private var isRefreshing = false
    @State private var showingSessionExpiredAlert = false
    
    // Add auth manager to handle logout
    @EnvironmentObject private var authManager: AuthManager
    
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
                    } else if let dashboard = vm.dashboardData {
                        animatedContentView(dashboard: dashboard)
                    } else if let error = vm.error {
                        animatedErrorView(error: error)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await refreshData()
            }
            .alert("Session Expired", isPresented: $showingSessionExpiredAlert) {
                Button("OK") {
                    // Perform logout when user acknowledges
                    authManager.logout()
                }
            } message: {
                Text("Your session has expired. Please log in again.")
            }
            .onChange(of: vm.error) { oldValue, newValue in
                // Check if error indicates session expiration
                if let error = newValue,
                   error.lowercased().contains("please login") ||
                   error.lowercased().contains("session expired") ||
                   error.lowercased().contains("unauthorized") {
                    showingSessionExpiredAlert = true
                }
            }
        }
        .task {
            if vm.dashboardData == nil {
                await vm.loadDashboard()
            }
        }
    }
    
    // MARK: - Loading Animation
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Animated placeholder cards
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
            
            // Animated chart placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .shimmering()
        }
    }
    
    // MARK: - Animated Content
    private func animatedContentView(dashboard: DashboardResponse) -> some View {
        Group {
            // Summary Cards with staggered animation
            summaryCardsView(totals: dashboard.totals)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            
            // Chart with fade-in animation
            chartSection(topCategories: dashboard.topCategories)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            // Recent expenses with slide-up animation
            recentExpensesSection(recentExpenses: dashboard.recentExpenses)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Updated Summary Cards with Staggered Animation
    private func summaryCardsView(totals: TotalExpenses) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnimatedSummaryCard(
                title: "Total Spent",
                value: totals.totalExpenses,
                format: .currency(code: "USD"),
                icon: "dollarsign.circle.fill",
                color: .blue,
                delay: 0.1
            )
            
            AnimatedSummaryCard(
                title: "Avg Transaction",
                value: totals.averageExpense,
                format: .currency(code: "USD"),
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                delay: 0.2
            )
            
            if let topCategory = vm.dashboardData?.topCategories.first {
                AnimatedSummaryCard(
                    title: "Top Category",
                    value: topCategory.totalAmount,
                    format: .currency(code: "USD"),
                    subtitle: topCategory.name,
                    icon: "crown.fill",
                    color: .orange,
                    delay: 0.3
                )
            } else {
                AnimatedSummaryCard(
                    title: "Top Category",
                    value: 0,
                    format: .currency(code: "USD"),
                    subtitle: "No data",
                    icon: "crown.fill",
                    color: .orange,
                    delay: 0.3
                )
            }
        }
    }
    
    // MARK: - Updated Chart Section with Animation
    private func chartSection(topCategories: [TopCategory]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .opacity(topCategories.isEmpty ? 0.5 : 1)
            
            if topCategories.isEmpty {
                emptyChartView
            } else {
                AnimatedPieChartView(topCategories: topCategories, colors: chartColors)
                
                // Animated Category Legend
                animatedCategoryLegendView(topCategories: topCategories)
            }
        }
        .padding()
        .background(Color.systemGray6)
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
    
    private func animatedCategoryLegendView(topCategories: [TopCategory]) -> some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(topCategories.enumerated()), id: \.offset) { index, category in
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
                    
                    Text(category.totalAmount, format: .currency(code: "USD"))
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
    
    // MARK: - Updated Recent Expenses with Animation
    private func recentExpensesSection(recentExpenses: [RecentExpense]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("View All") {
                    LogListContainerView(vm: .constant(LogListViewModel()))
                }
                .font(.subheadline)
            }
            
            if recentExpenses.isEmpty {
                Text("No recent expenses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(recentExpenses.prefix(5).enumerated()), id: \.offset) { index, expense in
                        AnimatedRecentExpenseRow(expense: expense, delay: Double(index) * 0.1)
                    }
                }
            }
        }
        .padding()
        .background(Color.systemGray6)
        .cornerRadius(12)
    }
    
    // MARK: - Updated Animated Error View with Session Expiration Handling
    private func animatedErrorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .scaleEffect(isRefreshing ? 1.2 : 1.0)
            
            Text("Failed to load dashboard")
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Only show retry button for non-session expiration errors
            if !error.lowercased().contains("please login") &&
               !error.lowercased().contains("session expired") {
                Button("Try Again") {
                    Task {
                        await refreshData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRefreshing)
                .overlay {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            } else {
                // For session expiration, show login message
                Button("Log In Again") {
                    authManager.logout()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Refresh Handler
    private func refreshData() async {
        isRefreshing = true
        await vm.loadDashboard()
        isRefreshing = false
    }
}

// MARK: - Animated Recent Expense Row
struct AnimatedRecentExpenseRow: View {
    let expense: RecentExpense
    let delay: Double
    
    @State private var isVisible = false
    
    private var category: Category {
        Category.fromBackendName(expense.category)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemNameIcon)
                .font(.callout)
                .foregroundColor(category.color)
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
                Text(expense.amount, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .opacity(isVisible ? 1 : 0)
                    .offset(x: isVisible ? 0 : 20)
                
                Text(formatDate(expense.expenseDate))
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
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Shimmer Effect for Loading
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
