//
//  LogListView.swift
//  AIExapenseTracker
//

import SwiftData
import SwiftUI
import WidgetKit

struct LogListView: View {

    @Binding var vm: LogListViewModel
    @ObservedObject private var lm = LocalizationManager.shared

    // All non-deleted records for the active log type, newest first.
    @Query private var allLocalLogs: [LocalExpenseLog]

    init(vm: Binding<LogListViewModel>, logType: LogType) {
        _vm = vm
        let rawValue = logType.rawValue
        _allLocalLogs = Query(
            filter: #Predicate<LocalExpenseLog> {
                $0.syncStatus != "pendingDelete" && $0.logType == rawValue
            },
            sort: \LocalExpenseLog.date,
            order: .reverse
        )
    }

    // Convert to ExpenseLog and apply category, search, and sort filters from the VM
    private var visibleLogs: [ExpenseLog] {
        let base = allLocalLogs.map { $0.toExpenseLog() }

        let categoryFiltered = vm.selectedCategories.isEmpty
            ? base
            : base.filter { vm.selectedCategories.contains($0.categoryEnum) }

        let searched: [ExpenseLog]
        if vm.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            searched = categoryFiltered
        } else {
            let query = vm.searchText.lowercased()
            searched = categoryFiltered.filter {
                $0.name.lowercased().contains(query)
                || $0.category.lowercased().contains(query)
                || $0.amountText.lowercased().contains(query)
            }
        }

        return searched.sorted { a, b in
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
    }

    // Page slice
    private var pagedLogs: [ExpenseLog] {
        let limit = vm.pageSize * vm.currentPage
        return Array(visibleLogs.prefix(limit))
    }

    var body: some View {
        Group {
#if os(iOS)
            iOSListView
#else
            macOSListView
#endif
        }
        .sheet(item: $vm.logToEdit, onDismiss: {
            vm.logToEdit = nil
        }) { log in
            LogFormView(vm: .init(logToEdit: log))
        }
        .searchable(
            text: $vm.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: lm.L(.searchPlaceholder)
        )
        .overlay {
            if allLocalLogs.isEmpty {
                ContentUnavailableView {
                    Label(lm.L(.noExpenses), systemImage: "list.bullet.rectangle.portrait")
                } description: {
                    Text(lm.L(.noExpensesHint))
                }
                .padding(.horizontal)
            } else if !vm.searchText.isEmpty && visibleLogs.isEmpty {
                ContentUnavailableView {
                    Label(lm.L(.noResults), systemImage: "magnifyingglass")
                } description: {
                    Text(lm.L(.noResultsHint))
                }
            }
        }
        .onChange(of: allLocalLogs) { _, newLogs in
            vm.hasMoreData = newLogs.count >= vm.pageSize * vm.currentPage
            pushLastExpenseToWidget(newLogs.map { $0.toExpenseLog() })
        }
        .onChange(of: vm.sortType)          { vm.resetPagination() }
        .onChange(of: vm.sortOrder)         { vm.resetPagination() }
        .onChange(of: vm.selectedCategories){ vm.resetPagination() }
        .onChange(of: vm.searchText)        { vm.resetPagination() }
    }

    // MARK: - iOS List

    private var iOSListView: some View {
        List {
            ForEach(groupedByMonth(pagedLogs), id: \.monthStart) { group in
                Section(header: Text(monthTitle(group.monthStart))) {
                    if group.logs.isEmpty {
                        ContentUnavailableView(lm.L(.noExpensesThisMonth), systemImage: "tray")
                    } else {
                        ForEach(group.logs) { log in
                            LogItemView(log: log)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    Button {
                                        let text = "\(log.name) - \(log.amount)$ - \(log.date)"
#if os(iOS)
                                        UIPasteboard.general.string = text
#elseif os(macOS)
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(text, forType: .string)
#endif
                                    } label: {
                                        Label(lm.L(.copy), systemImage: "doc.on.doc.fill")
                                    }

                                    ShareLink(
                                        item: shareText(for: log),
                                        preview: SharePreview(log.name, image: "")
                                    ) {
                                        Label(lm.L(.share), systemImage: "square.and.arrow.up")
                                    }

                                    Button(role: .destructive) {
                                        vm.logToEdit = log
                                    } label: {
                                        Label(lm.L(.edit), systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        vm.db.delete(log: log)
                                    } label: {
                                        Label(lm.L(.delete), systemImage: "trash.fill")
                                    }
                                }
                                .onTapGesture { vm.logToEdit = log }
                                .padding(.vertical, 4)
                                .onAppear {
                                    // Infinite scroll: load next page at the last visible item
                                    if log.id == pagedLogs.last?.id && vm.hasMoreData {
                                        vm.loadNextPage()
                                    }
                                }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { vm.db.delete(log: group.logs[$0]) }
                        }

                        if vm.isLoading {
                            HStack { Spacer(); ProgressView().padding(); Spacer() }
                        }

                        if !vm.hasMoreData && !pagedLogs.isEmpty {
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
            vm.resetPagination()
        }
    }

    // MARK: - macOS List

    private var macOSListView: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(pagedLogs) { log in
                        VStack {
                            LogItemView(log: log)
                            Divider()
                        }
                        .frame(minWidth: 0, maxHeight: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        .onTapGesture { vm.logToEdit = log }
                        .onAppear {
                            if log == pagedLogs.last && vm.hasMoreData {
                                vm.loadNextPage()
                            }
                        }
                        .contextMenu {
                            Button(lm.L(.edit)) { vm.logToEdit = log }
                            Button(lm.L(.delete)) { vm.db.delete(log: log) }
                        }
                    }

                    if vm.isLoading { ProgressView().padding() }

                    if !vm.hasMoreData && !pagedLogs.isEmpty {
                        Text(lm.L(.noMoreExpenses))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .contentMargins(.vertical, 8, for: .scrollContent)
            }
        }
    }

    // MARK: - Helpers

    private func groupedByMonth(_ logs: [ExpenseLog]) -> [(monthStart: Date, logs: [ExpenseLog])] {
        let groups = Dictionary(grouping: logs) { log in
            Calendar.current.date(
                from: Calendar.current.dateComponents([.year, .month], from: log.date)
            )!
        }
        return groups
            .map { (monthStart: $0.key, logs: $0.value) }
            .sorted { $0.monthStart > $1.monthStart }
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    private func shareText(for log: ExpenseLog) -> String {
        """
        Expense: \(log.name)
        Amount: \(log.amount)
        Date: \(log.date)
        Category: \(log.category)
        """
    }

    private func pushLastExpenseToWidget(_ logs: [ExpenseLog]) {
        guard let last = logs.max(by: { $0.date < $1.date }) else { return }
        let payload = LastExpenseWidgetData(
            name: last.name, date: last.date,
            amount: last.amount, currency: last.currency
        )
        guard let encoded = try? JSONEncoder().encode(payload) else { return }
        let shared = UserDefaults(suiteName: LastExpenseWidgetStore.appGroupID)
        shared?.set(encoded, forKey: LastExpenseWidgetStore.key)
        WidgetCenter.shared.reloadTimelines(ofKind: "aiexpensewidget")
    }
}
