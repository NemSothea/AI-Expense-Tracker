//
//  LogFormView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 17/12/24.
//

import SwiftUI

struct LogFormView: View {
    
    @State var vm: FormViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    @State private var error: String?
    
#if !os(macOS)
    var title: String {
        ((vm.expenseToEdit == nil) ? "Create" : "Edit") + " Expense"
    }
    
    var body: some View {
        NavigationStack {
            formView
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await self.onSaveTapped()
                            }
                        }
                        .disabled(vm.isSaveButtonDisabled || isSaving)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            self.onCancelTapped()
                        }
                    }
                }
        }
        .navigationBarTitle(title, displayMode: .large)
    }
#else
    var body: some View {
        VStack {
            formView.padding()
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            HStack {
                Button("Cancel") {
                    self.onCancelTapped()
                }
                Button("Save") {
                    Task {
                        await self.onSaveTapped()
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .disabled(vm.isSaveButtonDisabled || isSaving)
            }
            .padding()
        }
        .frame(minWidth: 300)
    }
#endif
    
    private var formView: some View {
        Form {
            TextField("Description", text: $vm.name)
                .disableAutocorrection(true)
            TextField("Amount", value: $vm.amount, formatter: vm.numberFormatter)
#if !os(macOS)
                .keyboardType(.numbersAndPunctuation)
#endif
            
            Picker(selection: $vm.category, label: Text("Category")) {
                ForEach(Category.allCases) { category in
                    Text(category.rawValue.capitalized).tag(category)
                }
            }
            DatePicker(selection: $vm.date, displayedComponents: [.date]) {
                Text("Date")
            }
        }
    }
    
    private func onCancelTapped() {
        self.dismiss()
    }
    
    private func onSaveTapped() async {
#if !os(macOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
        
        isSaving = true
        error = nil
        
        let success = await vm.save()
        
        if success {
            await MainActor.run {
                self.dismiss()
            }
        } else {
            // Error is handled in the ViewModel
            error = "Failed to save expense"
        }
        
        isSaving = false
    }
}
