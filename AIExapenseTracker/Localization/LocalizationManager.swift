//
//  LocalizationManager.swift
//  AIExapenseTracker
//
//  Created by sothea007
//

import SwiftUI

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case khmer   = "km"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .khmer:   return "ខ្មែរ"
        }
    }

    var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .khmer:   return "🇰🇭"
        }
    }
}

// MARK: - Localization Manager

final class LocalizationManager: ObservableObject {
    nonisolated(unsafe) static let shared = LocalizationManager()

    @AppStorage("appLanguage") var languageCode: String = AppLanguage.english.rawValue {
        didSet { objectWillChange.send() }
    }

    var current: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    @MainActor func set(_ language: AppLanguage) {
        languageCode = language.rawValue
        applyNavigationBarAppearance()
        refreshWindowHierarchy()
    }

    func L(_ key: LK) -> String {
        current == .khmer ? key.km : key.en
    }
}

// MARK: - UIKit Navigation Bar Appearance (iOS only)

#if os(iOS)
extension LocalizationManager {

    /// Call once on app launch and automatically on every language change via set(_:).
    @MainActor func applyNavigationBarAppearance() {
        let isKhmer = current == .khmer

        let largeTitleFont = isKhmer
            ? UIFont(name: "Battambang-Black", size: 34) ?? UIFont.boldSystemFont(ofSize: 34)
            : UIFont.boldSystemFont(ofSize: 34)

        let inlineTitleFont = isKhmer
            ? UIFont(name: "Battambang-Bold", size: 17) ?? UIFont.boldSystemFont(ofSize: 17)
            : UIFont.boldSystemFont(ofSize: 17)

        let backFont = isKhmer
            ? UIFont(name: "Battambang-Regular", size: 17) ?? UIFont.systemFont(ofSize: 17)
            : UIFont.systemFont(ofSize: 17)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.font: largeTitleFont]
        appearance.titleTextAttributes       = [.font: inlineTitleFont]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.font: backFont]

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
    }

    /// Forces existing navigation bars to re-read UIAppearance settings immediately.
    @MainActor private func refreshWindowHierarchy() {
        guard let scene  = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.keyWindow else { return }
        for view in window.subviews {
            view.removeFromSuperview()
            window.addSubview(view)
        }
    }
}
#endif

// MARK: - Font System

extension LocalizationManager {

    private enum BF {
        static let black   = "Battambang-Black"
        static let bold    = "Battambang-Bold"
        static let regular = "Battambang-Regular"
        static let light   = "Battambang-Light"
    }

    /// Returns Battambang for Khmer, system font otherwise — Dynamic Type aware.
    func font(for style: Font.TextStyle = .body) -> Font {
        guard current == .khmer else { return .system(style) }
        switch style {
        case .largeTitle:  return .custom(BF.black,   size: 34, relativeTo: .largeTitle)
        case .title:       return .custom(BF.bold,    size: 28, relativeTo: .title)
        case .title2:      return .custom(BF.bold,    size: 22, relativeTo: .title2)
        case .title3:      return .custom(BF.bold,    size: 20, relativeTo: .title3)
        case .headline:    return .custom(BF.bold,    size: 17, relativeTo: .headline)
        case .body:        return .custom(BF.regular, size: 17, relativeTo: .body)
        case .callout:     return .custom(BF.regular, size: 16, relativeTo: .callout)
        case .subheadline: return .custom(BF.regular, size: 15, relativeTo: .subheadline)
        case .footnote:    return .custom(BF.regular, size: 13, relativeTo: .footnote)
        case .caption:     return .custom(BF.light,   size: 12, relativeTo: .caption)
        case .caption2:    return .custom(BF.light,   size: 11, relativeTo: .caption2)
        @unknown default:  return .custom(BF.regular, size: 17, relativeTo: .body)
        }
    }

    // Convenience shortcuts
    var largeTitle: Font  { font(for: .largeTitle) }
    var title: Font       { font(for: .title) }
    var title2: Font      { font(for: .title2) }
    var title3: Font      { font(for: .title3) }
    var headline: Font    { font(for: .headline) }
    var appBody: Font     { font(for: .body) }
    var callout: Font     { font(for: .callout) }
    var subheadline: Font { font(for: .subheadline) }
    var footnote: Font    { font(for: .footnote) }
    var caption: Font     { font(for: .caption) }
    var caption2: Font    { font(for: .caption2) }
}

// MARK: - appFont View Extension

extension View {
    /// Use instead of `.font(.headline)` etc. — picks Battambang for Khmer automatically.
    func appFont(_ style: Font.TextStyle = .body) -> some View {
        font(LocalizationManager.shared.font(for: style))
    }
}

// MARK: - Localized Key (LK)

struct LK {
    let en: String
    let km: String
}

// MARK: - String Keys

extension LK {
    // Navigation / Tabs
    static let profile              = LK(en: "Profile",                       km: "ប្រវត្តិរូប")
    static let home                 = LK(en: "Home",                          km: "ទំព័រដើម")
    static let expense              = LK(en: "Expense",                       km: "ចំណាយ")

    // Profile Sections
    static let language             = LK(en: "Language",                      km: "ភាសា")
    static let monthlySummary       = LK(en: "Monthly Summary",               km: "សង្ខេបប្រចាំខែ")
    static let about                = LK(en: "About",                         km: "អំពីកម្មវិធី")

    // About rows
    static let appVersion           = LK(en: "App Version",                   km: "កំណែកម្មវិធី")
    static let createdBy            = LK(en: "Created by",                    km: "បង្កើតដោយ")
    static let appName              = LK(en: "AI Expense Tracker",            km: "កម្មវិធីតាមដានចំណាយ AI")

    // Currency
    static let totalUSD             = LK(en: "Total (USD)",                   km: "សរុប (ដុល្លារ)")
    static let totalKHR             = LK(en: "Total (KHR)",                   km: "សរុប (រៀល)")

    // General
    static let loading              = LK(en: "Loading…",                      km: "កំពុងផ្ទុក…")
    static let selectLanguage       = LK(en: "Select Language",               km: "ជ្រើសរើសភាសា")
    static let error                = LK(en: "Error",                         km: "កំហុស")
    static let ok                   = LK(en: "OK",                            km: "យល់ព្រម")

    // Dashboard
    static let dashboard            = LK(en: "Dashboard",                     km: "របាយការណ៍")
    static let totalSpent           = LK(en: "Total Spent",                   km: "ចំណាយសរុប")
    static let avgTransaction       = LK(en: "Avg Transaction",               km: "មធ្យមភាគ")
    static let topCategory          = LK(en: "Top Category",                  km: "ក្រុមកំពូល")
    static let noData               = LK(en: "No data",                       km: "គ្មានទិន្នន័យ")
    static let spendingByCategory   = LK(en: "Spending by Category",          km: "ចំណាយតាមក្រុម")
    static let noSpendingDataYet    = LK(en: "No spending data yet",          km: "មិនទាន់មានទិន្នន័យ")
    static let recentExpenses       = LK(en: "Recent Expenses",               km: "ចំណាយថ្មីៗ")
    static let noRecentExpenses     = LK(en: "No recent expenses",            km: "គ្មានចំណាយថ្មីៗ")
    static let noExpensesYet        = LK(en: "No Expenses Yet",               km: "មិនទាន់មានចំណាយ")
    static let dashboardEmptyHint   = LK(en: "Add your first expense to see your spending dashboard",
                                         km: "បន្ថែមការចំណាយដំបូងដើម្បីមើលរបាយការណ៍")

    // Expense List
    static let noExpenses           = LK(en: "No Expenses",                   km: "គ្មានការចំណាយ")
    static let noExpensesHint       = LK(en: "Please add expenses using the add button",
                                         km: "សូមបន្ថែមការចំណាយដោយប្រើប៊ូតុងបន្ថែម")
    static let noExpensesThisMonth  = LK(en: "No expenses this month",        km: "គ្មានការចំណាយខែនេះ")
    static let noMoreExpenses       = LK(en: "No more expenses",              km: "គ្មានការចំណាយបន្ថែម")
    static let addExpenseLog        = LK(en: "Add Expense Log",               km: "បន្ថែមការចំណាយ")
    static let add                  = LK(en: "Add",                           km: "បន្ថែម")

    // Context menu / actions
    static let copy                 = LK(en: "Copy",                          km: "ចម្លង")
    static let share                = LK(en: "Share",                         km: "ចែករំលែក")
    static let edit                 = LK(en: "Edit",                          km: "កែប្រែ")
    static let delete               = LK(en: "Delete",                        km: "លុប")

    // Form
    static let createExpense        = LK(en: "Create Expense Log",            km: "បង្កើតការចំណាយ")
    static let editExpense          = LK(en: "Edit Expense Log",              km: "កែប្រែការចំណាយ")
    static let save                 = LK(en: "Save",                          km: "រក្សាទុក")
    static let cancel               = LK(en: "Cancel",                        km: "បោះបង់")
    static let namePlaceholder      = LK(en: "Name, e.g. Lunch, Coffee…",     km: "ឈ្មោះ ឧ. អាហារថ្ងៃ, កាហ្វេ…")
    static let amount               = LK(en: "Amount",                        km: "ចំនួនទឹកប្រាក់")
    static let category             = LK(en: "Category",                      km: "ប្រភេទ")
    static let date                 = LK(en: "Date",                          km: "កាលបរិច្ឆេទ")
    static let notes                = LK(en: "Notes",                         km: "កំណត់ចំណាំ")
    static let notesPlaceholder    = LK(en: "Add a note (optional)",         km: "បន្ថែមកំណត់ចំណាំ (ស្រេចចិត្ត)")
    static let now                  = LK(en: "Now",                           km: "ឥឡូវ")

    // Name suggestions
    static let suggestionLunch         = LK(en: "Lunch",                         km: "អាហារថ្ងៃ")
    static let suggestionDinner        = LK(en: "Dinner",                        km: "អាហារល្ងាច")
    static let suggestionCoffee        = LK(en: "Coffee",                        km: "កាហ្វេ")
    static let suggestionGroceries     = LK(en: "Groceries",                     km: "គ្រឿងទេស")
    static let suggestionTransport     = LK(en: "Transport",                     km: "ការដឹកជញ្ជូន")
    static let suggestionEntertainment = LK(en: "Entertainment",                 km: "កំសាន្ត")
    static let suggestionShopping      = LK(en: "Shopping",                      km: "ទិញឥវ៉ាន់")
    static let suggestionUtilities     = LK(en: "Utilities",                     km: "សេវាសាធារណៈ")
    static let suggestionRent          = LK(en: "Rent",                          km: "ថ្លៃជួល")
    static let suggestionFuel          = LK(en: "Fuel",                          km: "សាំង")
    static let suggestionSnacks        = LK(en: "Snacks",                        km: "អាហារសម្រន់")
    static let suggestionMedical       = LK(en: "Medical",                       km: "វេជ្ជសាស្ត្រ")
    static let yesterday            = LK(en: "Yesterday",                     km: "ម្សិលមិញ")
    static let lastWeek             = LK(en: "Last Week",                     km: "សប្តាហ៍មុន")

    // Filter / Sort
    static let clearFilter          = LK(en: "Clear filter",                  km: "លុបតម្រង")
    static let sortBy               = LK(en: "Sort By",                       km: "តម្រៀបតាម")
    static let orderBy              = LK(en: "Order By",                      km: "លំដាប់")

    // About — extra rows
    static let contact              = LK(en: "Contact",                       km: "ទំនាក់ទំនង")
    static let rateApp              = LK(en: "Rate App",                      km: "វាយតម្លៃកម្មវិធី")
    static let footerCopyright      = LK(en: "© 2026 AIExpenseTracker · Built with ❤️ in Cambodia",
                                         km: "© ២០២៦ AIExpenseTracker · បង្កើតជាមួយ ❤️ នៅកម្ពុជា")

    // Sidebar / Split navigation (macOS / iPad)
    static let quiz                 = LK(en: "Quiz",                          km: "កម្រងសំណួរ")
    static let aiAssistant          = LK(en: "AI Assistant",                  km: "AI ជំនួយការ")
    static let receiptScanner       = LK(en: "Receipt Scanner",               km: "ស្កែនវិក្កយបត្រ")

    // Receipt Scanner — actions
    static let scanReceipt          = LK(en: "Scan Receipt",                  km: "ស្កែនវិក្កយបត្រ")
    static let scanNewReceipt       = LK(en: "Scan New Receipt",              km: "ស្កែនវិក្កយបត្រថ្មី")
    static let takePhoto            = LK(en: "Take Photo",                    km: "ថតរូបភាព")
    static let chooseFromLibrary    = LK(en: "Choose from Library",           km: "ជ្រើសរើសពីបណ្ណាល័យ")
    static let tryAgain             = LK(en: "Try Again",                     km: "សាកល្បងម្ដងទៀត")
    static let scanItems            = LK(en: "Items",                         km: "មុខ")
    static let addItemsPrefix       = LK(en: "Add",                           km: "បន្ថែម")
    static let foundSuffix          = LK(en: "Found",                         km: "បានរកឃើញ")

    // Receipt Scanner — state titles
    static let readyToScan          = LK(en: "Ready to Scan",                 km: "រួចរាល់សម្រាប់ស្កែន")
    static let loadingImage         = LK(en: "Loading Image",                 km: "កំពុងផ្ទុករូបភាព")
    static let readingText          = LK(en: "Reading Text",                  km: "កំពុងអានអត្ថបទ")
    static let scanFailed           = LK(en: "Scan Failed",                   km: "ស្កែនបរាជ័យ")

    // Receipt Scanner — state subtitles
    static let scanReadyHint        = LK(en: "Choose a receipt photo to get started",
                                         km: "ជ្រើសរើសរូបភាពវិក្កយបត្រដើម្បីចាប់ផ្ដើម")
    static let scanLoadingHint      = LK(en: "Preparing your image…",         km: "កំពុងរៀបចំរូបភាព…")
    static let scanScanningHint     = LK(en: "Extracting items and prices on-device…",
                                         km: "កំពុងទាញយកទំនិញ និងតម្លៃ…")
    static let scanSuccessHint      = LK(en: "Tap 'Add Items' to review and save",
                                         km: "ចុច 'បន្ថែមមុខ' ដើម្បីពិនិត្យ និងរក្សាទុក")
    static let scanFailedHint       = LK(en: "Tap 'Try Again' to retry",      km: "ចុច 'សាកល្បងម្ដងទៀត' ដើម្បីព្យាយាមម្ដងទៀត")

    // Receipt Scanner — tips
    static let tipGoodLighting      = LK(en: "Good lighting helps",           km: "ពន្លឺល្អជួយបានច្រើន")
    static let tipFlatReceipt       = LK(en: "Keep receipt flat",             km: "ទុកវិក្កយបត្រឱ្យរាបស្មើ")
    static let tipFullReceipt       = LK(en: "Capture the full receipt",      km: "ថតវិក្កយបត្រទាំងមូល")
    static let tipFreeNoKey         = LK(en: "100% free — no API key",        km: "ឥតគិតថ្លៃ ១០០%")

    // Export
    static let exportExpenses       = LK(en: "Export Expenses",               km: "នាំចេញចំណាយ")
    static let exportCSV            = LK(en: "Export as CSV",                 km: "នាំចេញជា CSV")
    static let exportPDF            = LK(en: "Export as PDF",                 km: "នាំចេញជា PDF")
    static let exportText           = LK(en: "Export as Text",                km: "នាំចេញជាអត្ថបទ")

    // Search
    static let search               = LK(en: "Search",                        km: "ស្វែងរក")
    static let searchPlaceholder    = LK(en: "Search expenses…",              km: "ស្វែងរកចំណាយ…")
    static let noResults            = LK(en: "No Results",                    km: "គ្មានលទ្ធផល")
    static let noResultsHint        = LK(en: "Try a different search term",   km: "សាកល្បងពាក្យស្វែងរកផ្សេង")
}
