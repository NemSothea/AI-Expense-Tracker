//
//  FilterCategoriesView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct LogListView: View {
    
    @Binding var vm: LogListViewModel
    @State private var isRefreshing = false
    @State private var pullToRefreshState = PullToRefreshState()
    
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: Expense?
    
    var body: some View {
        listView
            .sheet(item: $vm.expenseToEdit, onDismiss: {
                vm.expenseToEdit = nil
            }) { expense in
                LogFormView(vm: .init(expenseToEdit: expense, logListVM: vm))
            }
            // ADD THIS ALERT FOR iOS DELETE CONFIRMATION
            .alert("Delete Expense", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    expenseToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let expense = expenseToDelete {
                        Task {
                            await vm.deleteExpense(expense)
                        }
                    }
                    expenseToDelete = nil
                }
            } message: {
                if let expense = expenseToDelete {
                    Text("Are you sure you want to delete '\(expense.description)'?")
                } else {
                    Text("Are you sure you want to delete this expense?")
                }
            }
            .overlay {
                if vm.isLoading && vm.expenses.isEmpty {
                    ProgressView("Loading expenses...")
                } else if vm.expenses.isEmpty && !vm.isLoading {
                    emptyStateView
                }
            }
            .task {
                // Load initial data
                if vm.expenses.isEmpty {
                    await vm.loadExpenses(isRefreshing: true)
                }
            }
            .refreshable {
                await refreshData()
            }
            // macOS-specific refresh controls
            #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            await refreshData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                    .help("Refresh expenses")
                }
            }
            .contextMenu {
                Button(action: {
                    Task {
                        await refreshData()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isRefreshing)
            }
            #endif
    }
    
    private func refreshData() async {
        isRefreshing = true
        await vm.loadExpenses(isRefreshing: true)
        isRefreshing = false
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Expenses Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start tracking your expenses by tapping the add button above.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            #if os(macOS)
            Button("Refresh") {
                Task {
                    await refreshData()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshing)
            #endif
        }
        .padding()
    }
    
    var listView: some View {
        #if os(iOS)
        List {
            ForEach(vm.filteredExpenses) { expense in
                ExpenseItemView(expense: expense)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.expenseToEdit = expense
                    }
                    .padding(.vertical, 4)
                    .listRowSeparator(.visible)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        // Delete button (red)
                        Button(role: .destructive) {
                            expenseToDelete = expense
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        // Edit button from left side
                        Button {
                            vm.expenseToEdit = expense
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
            
            // Load more indicator
            if vm.hasMorePages && !vm.filteredExpenses.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        Task {
                            await vm.loadExpenses()
                        }
                    }
            }
        }
        .listStyle(.plain)
        #else
        ZStack {
            if vm.filteredExpenses.isEmpty && !vm.isLoading {
                emptyStateView
            } else {
                // macOS ScrollView with real pull-to-refresh
                ScrollView {
                    VStack(spacing: 0) {
                        // Pull to Refresh Indicator
                        PullToRefreshView(
                            isRefreshing: isRefreshing,
                            pullState: pullToRefreshState
                        ) {
                            Task {
                                await refreshData()
                            }
                        }
                        
                        LazyVStack(spacing: 0) {
                            ForEach(vm.filteredExpenses) { expense in
                                ExpenseItemView(expense: expense)
                                    .contentShape(Rectangle())
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .padding(.horizontal, 8)
                                    .onTapGesture {
                                        vm.expenseToEdit = expense
                                    }
                                    .contextMenu {
                                        Button("Edit") {
                                            vm.expenseToEdit = expense
                                        }
                                        Button("Delete") {
                                            Task {
                                                await vm.deleteExpense(expense)
                                            }
                                        }
                                        Divider()
                                        Button("Refresh List") {
                                            Task {
                                                await refreshData()
                                            }
                                        }
                                    }
                                
                                Divider()
                                    .padding(.leading, 60)
                            }
                            
                            // Load more indicator for macOS
                            if vm.hasMorePages && !vm.filteredExpenses.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .onAppear {
                                        Task {
                                            await vm.loadExpenses()
                                        }
                                    }
                            }
                        }
                    }
                }
                .background(
                    // This captures the drag gesture for pull-to-refresh
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                pullToRefreshState.coordinateSpace = geometry.frame(in: .global)
                            }
                    }
                )
            }
        }
        #endif
    }
}

// MARK: - Real Pull-to-Refresh Implementation for macOS
struct PullToRefreshState {
    var startY: CGFloat = 0
    var dragOffset: CGFloat = 0
    var isDragging = false
    var coordinateSpace: CGRect = .zero
    
    var pullProgress: Double {
        let progress = dragOffset / 80.0 // 80 points to trigger refresh
        return min(max(progress, 0), 1.0)
    }
    
    var shouldTriggerRefresh: Bool {
        return dragOffset >= 80 && !isDragging
    }
}

struct PullToRefreshView: View {
    let isRefreshing: Bool
    @State var pullState: PullToRefreshState
    let action: () async -> Void
    
    var body: some View {
        VStack {
            if isRefreshing || pullState.dragOffset > 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Refreshing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "arrow.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(pullState.pullProgress * 180))
                            
                            Text(pullState.dragOffset >= 80 ? "Release to refresh" : "Pull to refresh")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .opacity(pullState.pullProgress)
                    Spacer()
                }
                .frame(height: max(0, pullState.dragOffset))
                .background(Color.accentColor)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    handleDragChange(value)
                }
                .onEnded { value in
                    handleDragEnd(value)
                }
        )
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        let currentY = value.location.y
        let scrollViewTop = pullState.coordinateSpace.minY
        
        // Only trigger if we're at the top of the scroll view and pulling down
        if currentY > scrollViewTop && !pullState.isDragging {
            pullState.startY = currentY
            pullState.isDragging = true
        }
        
        if pullState.isDragging {
            let dragDistance = currentY - pullState.startY
            // Only allow positive drag (pulling down)
            if dragDistance > 0 {
                pullState.dragOffset = dragDistance
            }
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        if pullState.shouldTriggerRefresh && !isRefreshing {
            Task {
                await action()
            }
        }
        
        // Reset state with animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pullState.dragOffset = 0
            pullState.isDragging = false
        }
    }
}

struct ExpenseItemView: View {
    let expense: Expense
    
    private var category: Category {
        Category.fromBackendName(expense.category)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: category.systemNameIcon)
                .font(.title3)
                .foregroundColor(category.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description)
                    .font(.body)
                    .lineLimit(1)
                
                Text(expense.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount, format: .currency(code: "USD"))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(formatDate(expense.expenseDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d" // "Oct 20" format
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
}
