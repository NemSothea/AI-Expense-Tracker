//
//  aiexpensewidget.swift
//  aiexpensewidget
//
//  Created by sothea007 on 16/12/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        let shared = UserDefaults(suiteName: LastExpenseWidgetStore.appGroupID)
        let data = shared?.data(forKey: LastExpenseWidgetStore.key)

        let lastExpense: LastExpenseWidgetData? = data.flatMap { try? JSONDecoder().decode(LastExpenseWidgetData.self, from: $0) }
        return SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), lastExpense: lastExpense)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let shared = UserDefaults(suiteName: LastExpenseWidgetStore.appGroupID)
        let data = shared?.data(forKey: LastExpenseWidgetStore.key)

        let lastExpense: LastExpenseWidgetData? = data.flatMap { try? JSONDecoder().decode(LastExpenseWidgetData.self, from: $0) }
        return SimpleEntry(date: Date(), configuration: configuration, lastExpense: lastExpense)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let shared = UserDefaults(suiteName: LastExpenseWidgetStore.appGroupID)
        let data = shared?.data(forKey: LastExpenseWidgetStore.key)

        let lastExpense: LastExpenseWidgetData? = data.flatMap { try? JSONDecoder().decode(LastExpenseWidgetData.self, from: $0) }

        let entry = SimpleEntry(date: .now, configuration: configuration, lastExpense: lastExpense)
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let lastExpense: LastExpenseWidgetData?
}


struct aiexpensewidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family

    private var hasData: Bool { entry.lastExpense != nil }

    private var monthDayShort: String {
        guard let d = entry.lastExpense?.date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM d" // Dec 16
        return f.string(from: d)
    }

    private var weekdayShort: String {
        guard let d = entry.lastExpense?.date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "EEE" // Tue
        return f.string(from: d)
    }

    private var amountText: String {
        guard let e = entry.lastExpense else { return "No expense" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = e.currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: e.amount)) ?? "\(e.amount) \(e.currency)"
    }
    private var dayText: String {
        guard let d = entry.lastExpense?.date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "d"   // 16
        return f.string(from: d)
    }

    var body: some View {
        ZStack {
            // full, clean background (your current .fill.tertiary can look washed out) :contentReference[oaicite:1]{index=1}
            ContainerRelativeShape()
                .fill(.background)

            if !hasData {
                emptyState
                    .padding(12)
            } else {
                switch family {
                case .systemSmall:
                    small
                        .padding(12)

                case .systemMedium:
                    medium
                        .padding(14)

                case .systemLarge:
                    large
                        .padding(16)

                default:
                    medium
                        .padding(14)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("AI Expense", systemImage: "sparkles")
                .font(.headline)
            Text("No expenses yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var expenseName: String {
        guard let n = entry.lastExpense?.name, !n.isEmpty else { return "Expense" }
        return n
    }
    // ✅ Small: avoid header; show amount big + date tiny (NO truncation)
    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(amountText)
                .font(.system(size: 30, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color.pink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(expenseName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            HStack(spacing: 6) {
                Text("\(monthDayShort) • \(weekdayShort)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.tint)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }


    // ✅ Medium: left = date card, right = amount
    private var medium: some View {
        HStack(alignment: .center, spacing: 12) {
            dateCard(big: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Last expense")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(expenseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(amountText)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.pink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("Tap to open")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }


    // ✅ Large: same style, just more breathing room + subtitle
    private var large: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Top header
            HStack {
                Label("Last expense", systemImage: "sparkles")
                    .font(.headline)

                Spacer()

                Text(monthDayShort) // Dec 16
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.thinMaterial, in: Capsule())
            }

            // Name pill (fills space nicely)
            Text(expenseName)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Main content row: Date card + Amount card
            HStack(spacing: 12) {

                VStack(alignment: .leading, spacing: 10) {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(dayText) // 16
                        
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(weekdayShort) // Tue
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.tint.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.tint.opacity(0.35), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(amountText)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.pink)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("Tap to open")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }



    private func dateCard(big: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthDayShort)
                .font(big ? .headline : .subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(weekdayShort)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}





struct aiexpensewidget: Widget {
    let kind: String = "aiexpensewidget"

    var body: some WidgetConfiguration {
        
        AppIntentConfiguration(kind: kind, provider: Provider()) { entry in
            aiexpensewidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName(String(localized: "AI Expense"))
        .description(String(localized: "AI Expense"))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

