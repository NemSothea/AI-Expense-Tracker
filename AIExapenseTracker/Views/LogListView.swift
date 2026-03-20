//
//  LogListView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import FirebaseFirestore
import SwiftUI
import WidgetKit

struct LogListView: View {

    @Binding var vm: LogListViewModel
    @ObservedObject private var lm = LocalizationManager.shared

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
                    Label(lm.L(.noExpenses), systemImage: "list.bullet.rectangle.portrait")
                } description: {
                    Text(lm.L(.noExpensesHint))
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
        .onChange(of: vm.currentPage) {
            updateFireStoreQuery()
        }
        .onChange(of: firestoreLogs) { _, newLogs in
            vm.hasMoreData = newLogs.count >= vm.pageSize * vm.currentPage
            vm.isLoading = false
            pushLastExpenseToWidget(newLogs)
        }
        .onAppear {
            updateFireStoreQuery()
        }
    }
    
    // MARK: - Approach 1: Auto-loading with FirestoreQuery
    var autoLoadingListView: some View {
#if os(iOS)
        List {
            
                ForEach(groupedByMonth, id: \.monthStart) { group in
                    Section(header: Text(monthTitle(group.monthStart))) {
                        if group.logs.isEmpty {
                            ContentUnavailableView(lm.L(.noExpensesThisMonth), systemImage: "tray")
                        } else {
                            ForEach(group.logs) { log in
                                LogItemView(log: log)
                                    .contentShape(Rectangle())
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = "\(log.name) - \(log.amount)$ - \(log.date)"
                                        } label: {
                                            Label(lm.L(.copy), systemImage: "doc.on.doc.fill")
                                        }

                                        ShareLink(item: shareText(for: log), preview: SharePreview(log.name, image: "")) {
                                            Label(lm.L(.share), systemImage: "square.and.arrow.up")
                                        }

                                        Button(role: .destructive) { vm.logToEdit = log } label: {
                                            Label(lm.L(.edit), systemImage: "pencil")
                                        }

                                        Button(role: .destructive) { vm.db.delete(log: log) } label: {
                                            Label(lm.L(.delete), systemImage: "trash.fill")
                                        }
                                    }
                                    .onTapGesture {
                                        vm.logToEdit = log
                                    }
                                    .padding(.vertical, 4)
                                    .onAppear {
                                        // Load more when reaching the last item
                                        if log.id == firestoreLogs.last?.id && vm.hasMoreData && !vm.isLoading {
                                            vm.loadNextPage()
                                        }
                                    }
                            }
                            
                            .onDelete { indexSet in
                                indexSet.forEach { idx in
                                    let log = group.logs[idx]
                                    vm.db.delete(log: log)
                                }
                            }
                            
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
                                    Text(lm.L(.noMoreExpenses))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
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
                            Button(lm.L(.edit)) {
                                self.vm.logToEdit = log
                            }
                            Button(lm.L(.delete)) {
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
    
    private func onDelete(with indexSet: IndexSet) {
        indexSet.forEach { index in
            let log = firestoreLogs[index]
            vm.db.delete(log: log)
        }
    }
    
    func updateFireStoreQuery() {
        $firestoreLogs.predicates = vm.predicates
    }
    private func shareText(for log: ExpenseLog) -> String {
        """
        Expense: \(log.name)
        Amount: \(log.amount)
        Date: \(log.date)
        Category: \(log.category)
        """
    }
    private var groupedByMonth: [(monthStart: Date, logs: [ExpenseLog])] {
        // 1) Sort logs according to the selected sort options
        let sortedLogs = firestoreLogs.sorted { a, b in
            switch vm.sortType {
            case .date:
                return vm.sortOrder == .ascending ? a.date < b.date : a.date > b.date
            case .amount:
                return vm.sortOrder == .ascending ? a.amount < b.amount : a.amount > b.amount
            case .name:
                return vm.sortOrder == .ascending
                ? a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                : a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
            }
        }

        // 2) Group by (year, month)
        let groups = Dictionary(grouping: sortedLogs) { log in
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: log.date))!
        }

        // 3) Keep month sections ordered (usually newest month first)
        return groups
            .map { (monthStart: $0.key, logs: $0.value) } // already sorted within each month
            .sorted { $0.monthStart > $1.monthStart }
    }



    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy" // e.g. "Dec 2025"
        return f.string(from: date)
    }
  

    private func pushLastExpenseToWidget(_ logs: [ExpenseLog]) {
        guard let last = logs.max(by: { $0.date < $1.date }) else { return }

        let payload = LastExpenseWidgetData(name: last.name, date: last.date, amount: last.amount, currency: last.currency)
        guard let encoded = try? JSONEncoder().encode(payload) else { return }

        let shared = UserDefaults(suiteName: LastExpenseWidgetStore.appGroupID)
        shared?.set(encoded, forKey: LastExpenseWidgetStore.key)

        WidgetCenter.shared.reloadTimelines(ofKind: "aiexpensewidget")
    }

    
}

//#Preview {
//    @Previewable @State var vm = LogListViewModel()
//    return LogListView(vm: $vm)
//}
