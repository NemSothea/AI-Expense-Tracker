//
//  LogListContainerView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 16/12/24.
//

import SwiftData
import SwiftUI

struct LogListContainerView: View {

    @Binding var vm: LogListViewModel
    @ObservedObject private var lm = LocalizationManager.shared

    private let logType: LogType
    @Query private var allLocalLogs: [LocalExpenseLog]

    private var exportLogs: [ExpenseLog] { allLocalLogs.map { $0.toExpenseLog() } }

    init(vm: Binding<LogListViewModel>, logType: LogType) {
        _vm = vm
        self.logType = logType
        let rawValue = logType.rawValue
        _allLocalLogs = Query(
            filter: #Predicate<LocalExpenseLog> {
                $0.syncStatus != "pendingDelete" && $0.logType == rawValue
            },
            sort: \LocalExpenseLog.date,
            order: .reverse
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterCategoriesView(selectedCategories: $vm.selectedCategories)
            Divider()
            SelectSortOrderView(sortType: $vm.sortType, sortOrder: $vm.sortOrder)
            Divider()
            LogListView(vm: $vm, logType: logType)
        }
        .toolbar {
            // Export button
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    ShareLink(
                        item: ExportManager.csvURL(from: exportLogs),
                        preview: SharePreview(
                            "expenses.csv",
                            image: Image(systemName: "tablecells")
                        )
                    ) {
                        Label(lm.L(.exportCSV), systemImage: "tablecells")
                    }

                    ShareLink(
                        item: ExportManager.pdfURL(from: exportLogs),
                        preview: SharePreview(
                            "expenses.pdf",
                            image: Image(systemName: "doc.richtext")
                        )
                    ) {
                        Label(lm.L(.exportPDF), systemImage: "doc.richtext")
                    }

                    ShareLink(item: ExportManager.plainText(from: exportLogs)) {
                        Label(lm.L(.exportText), systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }

            // Add expense button
            ToolbarItem {
                Button {
                    vm.isLogFormPresented = true
                } label: {
#if os(macOS)
                    HStack {
                        Image(systemName: "plus")
                            .symbolRenderingMode(.monochrome)
                            .tint(.accentColor)
                        Text(lm.L(.addExpenseLog))
                    }
                    .foregroundStyle(Color.accentColor)
#else
                    Text(lm.L(.add))
#endif
                }
            }
        }
        .sheet(isPresented: $vm.isLogFormPresented) {
            LogFormView(vm: .init())
        }

#if !os(macOS)
        .navigationBarTitle(lm.L(.appName), displayMode: .inline)
#endif
    }
}
