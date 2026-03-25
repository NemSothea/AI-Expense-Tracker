//
//  VisionAddReceiptConfirmationView.swift
//  AIExapenseTracker
//

import SwiftUI

struct VisionAddReceiptConfirmationView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var vm: VisionAddReceiptConfirmationViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                List {
                    // Date + Currency row
                    HStack {
                        DatePicker(selection: $vm.date, displayedComponents: [.date]) {
                            Text("Date:")
                        }
                        Spacer()
                        Picker(selection: $vm.currencyCode, label: Text("Currency:")) {
                            ForEach(Locale.commonISOCurrencyCodes, id: \.self) { iso in
                                Text(iso).tag(iso)
                            }
                        }
                    }

                    switch horizontalSizeClass {
                    case .regular: regularRows
                    default:       compactRows
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Confirm Expenses")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { @MainActor in
                            vm.save()
                            presentationMode.wrappedValue.dismiss()
                            NotificationCenter.default.post(name: .navigateToExpenseList, object: nil)
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Reset", role: .destructive) {
                        vm.resetChanges()
                    }
                    .tint(.red)
                    .disabled(!vm.isEdited)
                }
            }
        }
    }

    // MARK: - Row layouts

    var regularRows: some View {
        ForEach($vm.expenseLogs) { log in
            HStack(spacing: 16) {
                HStack {
                    Text("Name:")
                    nameField(log)
                }
                HStack {
                    Text("Amount:")
                    amountField(log)
                }
                HStack {
                    categoryPicker(log)
                    CategoryImageView(category: log.wrappedValue.categoryEnum)
                }
            }
        }
        .onDelete { vm.expenseLogs.remove(atOffsets: $0) }
    }

    var compactRows: some View {
        ForEach($vm.expenseLogs) { log in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Name:").frame(maxWidth: 72, alignment: .leading)
                    Spacer()
                    nameField(log)
                }
                HStack {
                    Text("Amount:").frame(maxWidth: 72, alignment: .leading)
                    Spacer()
                    amountField(log)
                }
                HStack {
                    Text("Category")
                    Spacer()
                    categoryPicker(log)
                    CategoryImageView(category: log.wrappedValue.categoryEnum)
                }
            }
        }
        .onDelete { vm.expenseLogs.remove(atOffsets: $0) }
    }

    // MARK: - Field helpers

    func nameField(_ log: Binding<ExpenseLog>) -> some View {
        TextField("Name", text: log.name)
            .lineLimit(2)
            .textFieldStyle(.roundedBorder)
    }

    func amountField(_ log: Binding<ExpenseLog>) -> some View {
        TextField("Amount", value: log.amount, formatter: vm.numberFormatter)
            .textFieldStyle(.roundedBorder)
            #if !os(macOS)
            .keyboardType(.numbersAndPunctuation)
            #endif
    }

    func categoryPicker(_ log: Binding<ExpenseLog>) -> some View {
        Picker("Category:", selection: log.category) {
            ForEach(Category.allCases) { cat in
                Text(cat.rawValue.capitalized).tag(cat.rawValue)
            }
        }
    }
}
