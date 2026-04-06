//
//  ProfileView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 12/3/26.
//

import SwiftUI

struct ProfileView: View {

    @StateObject private var vm  = ProfileViewModel()
    @ObservedObject private var lm = LocalizationManager.shared
    @Environment(AppSettings.self) private var settings
    @State private var expandedMonths: Set<String> = []

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            Form {
                appHeaderSection
                logTypeSection
                languageSection
                monthlySummarySection
                aboutSection
            }
            .navigationTitle(lm.L(.profile))
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
        }
        .onAppear  { vm.setupListener(for: settings.selectedLogType) }
        .onDisappear { vm.removeListener() }
        .onChange(of: settings.selectedLogType) { _, newType in
            vm.setupListener(for: newType)
        }
        .alert(lm.L(.error), isPresented: $vm.showError) {
            Button(lm.L(.ok), role: .cancel) {}
        } message: {
            Text(vm.errorMessage)
        }
    }

    // MARK: - App Header

    private var appHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(lm.L(.appName))
                        .appFont(.title3)
                        .fontWeight(.bold)

                    Text("v\(appVersion) (\(buildNumber))")
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .appFont(.caption)
                            .foregroundStyle(.green)
                        Text("AIExpenseTracker")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Log Type Section

    @ViewBuilder
    private var logTypeSection: some View {
        Section {
            ForEach(LogType.allCases) { logType in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        settings.selectedLogType = logType
                    }
                } label: {
                    HStack {
                        Image(systemName: logType.icon)
                            .font(.title2)
                            .frame(width: 28)
                        Text(logType.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if settings.selectedLogType == logType {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        } header: {
            Label("Log Owner", systemImage: "person.2.fill")
        } footer: {
            Text("Choose whose expense logs to view and manage.")
                .appFont(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        Section {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        lm.set(lang)
                    }
                } label: {
                    HStack {
                        Text(lang.flagEmoji)
                            .font(.title2)
                        Text(lang.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if lm.current == lang {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        } header: {
            Label(lm.L(.language), systemImage: "globe")
        }
    }

    // MARK: - Monthly Summary Section

    private var monthlySummarySection: some View {
        Section {
            if vm.isLoading {
                HStack {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text(lm.L(.loading))
                        .foregroundStyle(.secondary)
                }
            } else if vm.monthlySummaries.isEmpty {
                Text(lm.L(.noExpenses))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(vm.monthlySummaries) { summary in
                    monthRow(summary)
                }
            }
        } header: {
            Label(lm.L(.monthlySummary), systemImage: "calendar")
        }
    }

    @ViewBuilder
    private func monthRow(_ summary: MonthlyExpenseSummary) -> some View {
        let isExpanded = expandedMonths.contains(summary.id)

        VStack(alignment: .leading, spacing: 0) {
            // Month header row (tap to expand)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedMonths.remove(summary.id)
                    } else {
                        expandedMonths.insert(summary.id)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.displayMonth)
                            .appFont(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        // Compact currency pills always visible
                        HStack(spacing: 6) {
                            ForEach(summary.sortedCurrencies, id: \.self) { currency in
                                if let total = summary.totalsByCurrency[currency] {
                                    currencyPill(amount: total, currency: currency)
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)

            // Expanded detail rows
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(summary.sortedCurrencies, id: \.self) { currency in
                        if let total = summary.totalsByCurrency[currency] {
                            currencyDetailRow(amount: total, currency: currency)
                        }
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func currencyPill(amount: Double, currency: String) -> some View {
        let (color, symbol) = currencyStyle(currency)
        return Text("\(symbol)\(shortAmount(amount))")
            .appFont(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func currencyDetailRow(amount: Double, currency: String) -> some View {
        let (color, _) = currencyStyle(currency)
        return HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(currencyLabel(currency))
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amount, format: .currency(code: currency))
                .appFont(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            aboutRow(
                icon: "info.circle.fill",
                iconColor: .blue,
                title: lm.L(.appVersion),
                value: "v\(appVersion) (\(buildNumber))"
            )

            aboutRow(
                icon: "person.fill",
                iconColor: .indigo,
                title: lm.L(.createdBy),
                value: "AIExpenseTracker"
            )

            aboutRow(
                icon: "envelope.fill",
                iconColor: .teal,
                title: lm.L(.contact),
                value: "sothea007"
            )

            aboutRow(
                icon: "star.fill",
                iconColor: .orange,
                title: lm.L(.rateApp),
                value: ""
            )
        } header: {
            Label(lm.L(.about), systemImage: "app.badge")
        } footer: {
            Text(lm.L(.footerCopyright))
                .appFont(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    private func aboutRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .appFont(.body)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .appFont(.subheadline)
        }
    }

    // MARK: - Helpers

    private func currencyStyle(_ currency: String) -> (Color, String) {
        switch currency {
        case "USD": return (.blue,   "$")
        case "KHR": return (.red,    "៛")
        case "EUR": return (.purple, "€")
        default:    return (.gray,   currency)
        }
    }

    private func currencyLabel(_ currency: String) -> String {
        switch currency {
        case "USD": return lm.current == .khmer ? "ដុល្លារ (USD)" : "US Dollar (USD)"
        case "KHR": return lm.current == .khmer ? "រៀល (KHR)"     : "Khmer Riel (KHR)"
        default:    return currency
        }
    }

    private func shortAmount(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

#Preview {
    ProfileView()
}
