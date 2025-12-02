//
//  LogListView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import FirebaseFirestore
import SwiftUI

struct LogListView: View {
    
    @Binding var vm: LogListViewModel
    @State private var allLogs: [ExpenseLog] = [] // For manual pagination
    
    @FirestoreQuery(collectionPath: "logs", predicates: [])
    private var firestoreLogs: [ExpenseLog]
    
    var body: some View {
        Group {
            // Choose either approach:
            // Approach 1: Auto-loading with FirestoreQuery (simpler)
            autoLoadingListView
  
        }
        .sheet(item: $vm.logToEdit, onDismiss: {
            vm.logToEdit = nil
        }) { log in
            LogFormView(vm: .init(logToEdit: log))
        }
        .overlay {
            if firestoreLogs.isEmpty && !vm.isLoading {
                ContentUnavailableView {
                    Label("No Expenses", systemImage: "list.bullet.rectangle.portrait")
                } description: {
                    Text("Please add expenses using the add button")
                }
                .padding(.horizontal)
            }
        }
        .onChange(of: vm.sortType) {
            vm.resetPagination()
            updateFireStoreQuery()
        }
        .onChange(of: vm.sortOrder) {
            vm.resetPagination()
            updateFireStoreQuery()
        }
        .onChange(of: vm.selectedCategories) {
            vm.resetPagination()
            updateFireStoreQuery()
        }
        .onChange(of: firestoreLogs) { _, newLogs in
            // Check if we have more data to load
            vm.hasMoreData = newLogs.count >= vm.pageSize * vm.currentPage
            vm.isLoading = false
        }
        .onAppear {
            // For manual pagination
            loadInitialData()
        }
    }
    
    // MARK: - Approach 1: Auto-loading with FirestoreQuery
    var autoLoadingListView: some View {
#if os(iOS)
        List {
            ForEach(firestoreLogs) { log in
                LogItemView(log: log)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.logToEdit = log
                    }
                    .padding(.vertical, 4)
                    .onAppear {
                        // Load more when reaching the last item
                        if log == firestoreLogs.last && vm.hasMoreData && !vm.isLoading {
                            vm.loadNextPage()
                        }
                    }
            }
            .onDelete(perform: self.onDelete)
            
            // Loading indicator at the bottom
            if vm.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
            
            // No more data indicator
            if !vm.hasMoreData && !firestoreLogs.isEmpty {
                HStack {
                    Spacer()
                    Text("No more expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Pull to refresh
            vm.resetPagination()
            updateFireStoreQuery()
        }
#else
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(firestoreLogs) { log in
                        VStack {
                            LogItemView(log: log)
                            Divider()
                        }
                        .frame(minWidth: 0, maxHeight: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        .onTapGesture {
                            self.vm.logToEdit = log
                        }
                        .onAppear {
                            // Load more when reaching the last item
                            if log == firestoreLogs.last && vm.hasMoreData && !vm.isLoading {
                                vm.loadNextPage()
                            }
                        }
                        .contextMenu {
                            Button("Edit") {
                                self.vm.logToEdit = log
                            }
                            Button("Delete") {
                                vm.db.delete(log: log)
                            }
                        }
                    }
                    
                    // Loading indicator
                    if vm.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    // No more data indicator
                    if !vm.hasMoreData && !firestoreLogs.isEmpty {
                        Text("No more expenses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .contentMargins(.vertical, 8, for: .scrollContent)
            }
        }
#endif
    }
    
    // MARK: - Approach 2: Manual Pagination
    var manualPaginationListView: some View {
        List {
            ForEach(allLogs) { log in
                LogItemView(log: log)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.logToEdit = log
                    }
                    .padding(.vertical, 4)
                    .onAppear {
                        // Load more when reaching the last item
                        if log == allLogs.last && vm.hasMoreData && !vm.isLoading {
                            loadNextPage()
                        }
                    }
            }
            .onDelete(perform: self.onDelete)
            
            // Load More Button
            if vm.hasMoreData {
                HStack {
                    Spacer()
                    Button(action: {
                        loadNextPage()
                    }) {
                        if vm.isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Load More")
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .disabled(vm.isLoading)
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            } else if !allLogs.isEmpty {
                HStack {
                    Spacer()
                    Text("No more expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Pull to refresh
            allLogs.removeAll()
            vm.resetPagination()
            loadInitialData()
        }
    }
    
    private func onDelete(with indexSet: IndexSet) {
        indexSet.forEach { index in
            let log = firestoreLogs[index]
            vm.db.delete(log: log)
        }
    }
    
    func updateFireStoreQuery() {
        $firestoreLogs.predicates = vm.predicates
    }
    
    // MARK: - Manual Pagination Methods
    
    private func loadInitialData() {
        vm.resetPagination()
        vm.loadNextPageManually { [self] newLogs in
            if let newLogs = newLogs {
                self.allLogs = newLogs
            }
        }
    }
    
    private func loadNextPage() {
        vm.loadNextPageManually { [self] newLogs in
            if let newLogs = newLogs {
                self.allLogs.append(contentsOf: newLogs)
            }
        }
    }
}

//#Preview {
//    @Previewable @State var vm = LogListViewModel()
//    return LogListView(vm: $vm)
//}
