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
    @ObservedObject private var lm = LocalizationManager.shared
    @FocusState private var focusedField: Field?

    enum Field { case name, amount, notes }

    private var nameSuggestions: [String] {
        [
            lm.L(.suggestionLunch),
            lm.L(.suggestionDinner),
            lm.L(.suggestionCoffee),
            lm.L(.suggestionGroceries),
            lm.L(.suggestionTransport),
            lm.L(.suggestionEntertainment),
            lm.L(.suggestionShopping),
            lm.L(.suggestionUtilities),
            lm.L(.suggestionRent),
            lm.L(.suggestionFuel),
            lm.L(.suggestionSnacks),
            lm.L(.suggestionMedical),
        ]
    }

    // MARK: - Platform-adaptive helpers

    /// Body text size — larger on Mac so the form doesn't feel microscopic.
    private var fieldFont: Font {
        #if os(macOS)
        return .system(size: 14)
        #else
        return .body
        #endif
    }

    /// Suggestion chip label size.
    private var chipFont: Font {
        #if os(macOS)
        return .system(size: 13)
        #else
        return .caption
        #endif
    }

    /// Notes editor height — Mac gets more vertical space.
    private var notesMinHeight: CGFloat {
        #if os(macOS)
        return 120
        #else
        return 80
        #endif
    }

    // MARK: - Body
    //
    // Single body for both platforms.
    // • .cancellationAction  → navigation-bar leading on iOS  | toolbar left on Mac
    // • .confirmationAction  → navigation-bar trailing on iOS | toolbar right on Mac
    // • ⌘↩ / Esc keyboard shortcuts only registered on Mac (no-op on iOS).

    var body: some View {
        NavigationStack {
            formView
                .navigationTitle(lm.L(vm.logToEdit == nil ? .createExpense : .editExpense))
#if os(iOS)
                .navigationBarTitleDisplayMode(.large)
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(lm.L(.cancel)) { onCancelTapped() }
                            .fixedSize()
#if os(macOS)
                            .keyboardShortcut(.escape, modifiers: [])
#endif
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(lm.L(.save)) { onSaveTapped() }
                            .fixedSize()
                            .disabled(vm.isSaveButtonDisabled)
#if os(macOS)
                            .keyboardShortcut(.return, modifiers: .command)
#endif
                    }
                }
        }
#if os(macOS)
        // Give the sheet a comfortable fixed minimum size on Mac.
        .frame(minWidth: 520, minHeight: 580)
#endif
    }

    // MARK: - Form
    //
    // LabeledContent produces a native two-column (label | control) layout on
    // Mac Catalyst / macOS, while collapsing to the standard stacked iOS style
    // on iPhone — no extra conditional code required.

    private var formView: some View {
        Form {

            // ── Name ──────────────────────────────────────────────────────────
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(lm.L(.namePlaceholder), text: $vm.name)
                        .font(fieldFont)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .name)

                    if focusedField == .name || vm.name.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(
                                    nameSuggestions.filter {
                                        vm.name.isEmpty || $0.lowercased().contains(vm.name.lowercased())
                                    }.prefix(6),
                                    id: \.self
                                ) { suggestion in
                                    Button {
                                        vm.name = suggestion
                                        focusedField = .amount
                                    } label: {
                                        Text(suggestion)
                                            .font(chipFont)
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

            // ── Amount ────────────────────────────────────────────────────────
            Section {
                LabeledContent(lm.L(.amount)) {
                    HStack {
                        TextField(lm.L(.amount), text: $vm.amountText)
                            .font(fieldFont)
                            .focused($focusedField, equals: .amount)
                            .multilineTextAlignment(.trailing)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .onSubmit { vm.commitAmount() }

                        Menu {
                            ForEach([1, 3, 5, 10, 20, 50, 100], id: \.self) { preset in
                                Button("\(preset)") {
                                    vm.amount = Double(preset)
                                    vm.amountText = vm.numberFormatter.string(
                                        from: NSNumber(value: Double(preset))
                                    ) ?? "\(preset)"
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onChange(of: focusedField) { old, _ in
                if old == .amount { vm.commitAmount() }
            }

            // ── Notes ─────────────────────────────────────────────────────────
            Section(header: Text(lm.L(.notes)).font(.callout)) {
                ZStack(alignment: .topLeading) {
                    if vm.notes.isEmpty {
                        Text(lm.L(.notesPlaceholder))
                            .font(fieldFont)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $vm.notes)
                        .font(fieldFont)
                        .focused($focusedField, equals: .notes)
                        .frame(minHeight: notesMinHeight)
                }
            }

            // ── Category ──────────────────────────────────────────────────────
            Section {
                LabeledContent(lm.L(.category)) {
                    Picker("", selection: $vm.category) {
                        ForEach(Category.allCases) { category in
                            Text(category.localizedName).tag(category)
                        }
                    }
                    .labelsHidden()
#if os(macOS)
                    // Constrain picker width so it doesn't stretch edge-to-edge.
                    .frame(maxWidth: 220)
#endif
                }
            }

            // ── Date ──────────────────────────────────────────────────────────
            Section {
                LabeledContent(lm.L(.date)) {
                    DatePicker(
                        "",
                        selection: $vm.date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .environment(
                        \.locale,
                        lm.current == .khmer ? Locale(identifier: "km_KH") : .current
                    )
                }

                HStack {
                    Button(lm.L(.now))       { vm.date = Date() }
                    Spacer()
                    Button(lm.L(.yesterday)) {
                        vm.date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                    Spacer()
                    Button(lm.L(.lastWeek))  {
                        vm.date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                    }
                }
                .font(.callout)
                .foregroundColor(.accentColor)
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func onCancelTapped() {
        dismiss()
    }

    private func onSaveTapped() {
#if os(iOS)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
#endif
        vm.save()
        dismiss()
    }
}
