//
//  FilterCategoriesView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct LogListView: View {
    @Binding var vm: LogListViewModel
    
    var body: some View {
        listView
            .sheet(item: $vm.expenseToEdit, onDismiss: {
                vm.expenseToEdit = nil
            }) { expense in
                LogFormView(vm: .init(expenseToEdit: expense, logListVM: vm))
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
                await vm.loadExpenses(isRefreshing: true)
            }
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
                ScrollView {
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
        }
#endif
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

