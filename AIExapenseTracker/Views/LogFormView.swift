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
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, amount
    }
    
    let nameSuggestions = ["Lunch", "Dinner", "Coffee", "Groceries", "Transport", "Entertainment", "Shopping", "Utilities", "Rent", "Fuel", "Snacks", "Medical"]
    
#if !os(macOS)
    var title: String {
        ((vm.logToEdit == nil) ? "Create" : "Edit") + " Expense Log"
    }
    
    var body: some View {
        NavigationStack {
            formView
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            self.onSaveTapped()
                        }
                        .disabled(vm.isSaveButtonDisabled)
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
            HStack {
                Button("Cancel") {
                    self.onCancelTapped()
                }
                Button("Save") {
                    self.onSaveTapped()
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .disabled(vm.isSaveButtonDisabled)
            }
            .padding()
        }
        .frame(minWidth: 300)
    }
    
#endif
    
    private var formView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Name : ex. Drink with ex. girlfriend", text: $vm.name)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .name)
                    
                    // Suggestions only show when name field is focused or empty
                    if focusedField == .name || vm.name.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(nameSuggestions.filter {
                                    vm.name.isEmpty || $0.lowercased().contains(vm.name.lowercased())
                                }.prefix(6), id: \.self) { suggestion in
                                    Button(action: {
                                        vm.name = suggestion
                                        focusedField = .amount
                                    }) {
                                        Text(suggestion)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            
            Section {
                HStack {
                    TextField("Amount", value: $vm.amount, formatter: vm.numberFormatter)
                        .focused($focusedField, equals: .amount)
#if !os(macOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                    
                    // Quick amount buttons
                    Menu {
                        ForEach([1, 3, 5, 10, 20, 50, 100], id: \.self) { amount in
                            Button("\(amount)") {
                                vm.amount = Double(amount)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section {
                Picker(selection: $vm.category, label: Text("Category")) {
                    ForEach(Category.allCases) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }
            }
            
            Section {
                DatePicker(selection: $vm.date, displayedComponents: [.date, .hourAndMinute]) {
                    Text("Date")
                }
                
                // Quick date buttons
                HStack {
                    Button("Now") {
                        vm.date = Date()
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    Button("Yesterday") {
                        vm.date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    Button("Last Week") {
                        vm.date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func onCancelTapped() {
        self.dismiss()
    }
    
    private func onSaveTapped() {
#if !os(macOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
        self.vm.save()
        self.dismiss()
    }
}
#Preview {
    LogFormView(vm: .init())
}
