//
//  ReceiptTextParser.swift
//  AIExapenseTracker
//
//  Converts raw OCR lines (Vision framework) into a VisionReceipt.
//
//  Two layout strategies (both are always tried; winner has more items):
//
//  ROW layout    — "Name    Price" on the same line (or price 1–3 lines below name)
//  COLUMN layout — Vision reads ALL names first, then ALL prices as two separate columns.
//                  Pairing is done END-ALIGNED so that a missing OCR name at the top
//                  does not corrupt every subsequent pair.
//

import Foundation

struct ReceiptTextParser {

    // MARK: - Annotated line

    private struct AL {
        let raw: String
        let priceValue: Double?
        let priceStart: String.Index?
        let isSummary: Bool
    }

    // MARK: - Public API

    static func parse(lines: [String]) -> VisionReceipt {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let annotated: [AL] = cleaned.map { raw -> AL in
            if let (val, range) = findLastPrice(in: raw) {
                return AL(raw: raw, priceValue: val, priceStart: range.lowerBound,
                          isSummary: isSummaryLine(raw))
            }
            return AL(raw: raw, priceValue: nil, priceStart: nil,
                      isSummary: isSummaryLine(raw))
        }

        // Metadata
        var date: Date?
        var currency = "USD"

        let storeName = annotated.first {
            $0.priceValue == nil && !$0.isSummary && $0.raw.count > 2
        }?.raw

        for al in annotated {
            let lower = al.raw.lowercased()
            if lower.contains("khr") || al.raw.contains("៛") { currency = "KHR" }
            else if al.raw.contains("£") { currency = "GBP" }
            else if al.raw.contains("€") { currency = "EUR" }
            if date == nil { date = extractDate(from: al.raw) }
        }

        // Choose strategy.
        // Use column layout when Vision clearly read the receipt as two separate
        // columns (≥3 consecutive price-only lines). Otherwise prefer row layout.
        // If the preferred strategy returns 0 items, fall back to the other.
        let preferColumn = isColumnLayout(annotated)
        let primary   = preferColumn
            ? parseColumnLayout(annotated, storeName: storeName)
            : parseRowLayout(annotated)
        let secondary = preferColumn
            ? parseRowLayout(annotated)
            : parseColumnLayout(annotated, storeName: storeName)
        let items = primary.isEmpty ? secondary : primary

        return VisionReceipt(storeName: storeName, items: items,
                             currency: currency, date: date)
    }

    // MARK: - Layout helpers

    /// Column layout: ≥3 consecutive lines that are pure price (no item name before it).
    /// This pattern occurs when Vision reads a two-column receipt left-column-first,
    /// producing all names then all prices as separate runs.
    private static func isColumnLayout(_ lines: [AL]) -> Bool {
        var streak = 0
        for al in lines {
            if isPriceOnly(al) { streak += 1 } else { streak = 0 }
            if streak >= 3 { return true }
        }
        return false
    }

    /// True when the entire line is just a price token (no name before it).
    private static func isPriceOnly(_ al: AL) -> Bool {
        guard let priceStart = al.priceStart else { return false }
        let before = String(al.raw[al.raw.startIndex ..< priceStart])
            .trimmingCharacters(in: CharacterSet(charactersIn: "$£€¥฿₫₩ "))
        return before.isEmpty
    }

    // MARK: - Column layout strategy

    private static func parseColumnLayout(_ lines: [AL], storeName: String?) -> [VisionReceiptItem] {
        // ── Names: longest consecutive run of valid name lines ────────────
        // Item names always appear as a tight consecutive block on a real receipt.
        // Noise lines (column headers, cashier name, size-only lines, etc.) appear
        // as isolated singles scattered around — they never form a long run.
        // Picking the FIRST longest run correctly identifies the item name block
        // and ignores all noise.
        var bestRun: [String] = []
        var currentRun: [String] = []

        for al in lines {
            let valid: Bool
            if al.priceValue != nil || al.isSummary || al.raw.count < 2 {
                valid = false
            } else {
                let name = cleanName(al.raw)
                valid = !name.isEmpty && name.count >= 2 && !name.contains(":") && name != storeName
            }
            if valid {
                currentRun.append(cleanName(al.raw))
            } else {
                if currentRun.count > bestRun.count { bestRun = currentRun }
                currentRun = []
            }
        }
        if currentRun.count > bestRun.count { bestRun = currentRun }
        let itemNames = bestRun

        // ── Prices: longest consecutive price-only block ──────────────────
        // Isolated price-only lines (e.g. a table/order number like "34115")
        // are excluded — they are not part of the real price column.
        var bestBlock: [AL] = []
        var currentBlock: [AL] = []

        for al in lines {
            if isPriceOnly(al) {
                currentBlock.append(al)
            } else {
                if currentBlock.count > bestBlock.count { bestBlock = currentBlock }
                currentBlock = []
            }
        }
        if currentBlock.count > bestBlock.count { bestBlock = currentBlock }
        let allPriceOnly = bestBlock

        // ── Trim footer prices (Sub-total, Tax, Total, Change…) ───────────
        let surplus = allPriceOnly.count - itemNames.count
        let summariesToTrim = min(max(surplus, 0), 5)
        let itemPrices = allPriceOnly.dropLast(summariesToTrim)

        // ── Start-aligned pairing ─────────────────────────────────────────
        // Unit prices are at the START of the price block (before duplicate
        // amount columns and totals), so prefix-align instead of suffix-align.
        let n = min(itemNames.count, itemPrices.count)
        let finalNames  = Array(itemNames.prefix(n))
        let finalPrices = Array(itemPrices.prefix(n))

        return zip(finalNames, finalPrices).compactMap { name, priceLine in
            guard let price = priceLine.priceValue, price > 0 else { return nil }
            return VisionReceiptItem(name: name, quantity: 1, price: price,
                                     category: inferCategory(from: name))
        }
    }

    // MARK: - Row layout strategy

    private static func parseRowLayout(_ lines: [AL]) -> [VisionReceiptItem] {
        var items: [VisionReceiptItem] = []
        var usedNameIndices = Set<Int>()

        for (i, al) in lines.enumerated() {
            guard !al.isSummary,
                  let price = al.priceValue, price > 0,
                  let priceStart = al.priceStart else { continue }

            var name = cleanName(String(al.raw[al.raw.startIndex ..< priceStart]))

            // Look back up to 3 lines for a name-only line
            if name.isEmpty {
                for j in stride(from: i - 1, through: max(0, i - 3), by: -1) {
                    guard !usedNameIndices.contains(j) else { continue }
                    let prev = lines[j]
                    guard prev.priceValue == nil, !prev.isSummary,
                          prev.raw.count >= 2 else { continue }
                    let candidate = cleanName(prev.raw)
                    if !candidate.isEmpty {
                        name = candidate
                        usedNameIndices.insert(j)
                        break
                    }
                }
            }

            guard !name.isEmpty, name.count >= 2, !name.contains(":") else { continue }
            items.append(VisionReceiptItem(name: name, quantity: 1, price: price,
                                           category: inferCategory(from: name)))
        }
        return items
    }

    // MARK: - Core: find the LAST price in a line

    private static func findLastPrice(in line: String) -> (Double, Range<String.Index>)? {
        let pattern =
            #"[\$£€¥฿₫₩]?\s*"# +
            #"(?:"# +
            #"\d{1,3}(?:,\d{3})+(?:[.]\d{1,2})?"# + // 1,234.50 or 1,234
            #"|"# +
            #"\d+[.,]\d{1,2}"# +                     // 4.50 or 4,50
            #"|"# +
            #"\d{4,9}(?![.,\d])"# +                  // 25000 (KHR/JPY)
            #")"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        guard let last = matches.last,
              let fullRange = Range(last.range, in: line) else { return nil }

        let raw = String(line[fullRange])
        guard let price = parsePrice(raw),
              price >= 0.01,
              !(raw.trimmingCharacters(in: .whitespaces).allSatisfy({ $0.isNumber }) && price < 500)
        else { return nil }

        return (price, fullRange)
    }

    private static func parsePrice(_ raw: String) -> Double? {
        var s = raw
            .replacingOccurrences(of: "[$£€¥฿₫₩]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        let commas = s.filter { $0 == "," }.count
        let dots   = s.filter { $0 == "." }.count

        if dots >= 1 && commas >= 1 {
            s = s.replacingOccurrences(of: ",", with: "")          // "1,234.50"
        } else if commas == 1 && dots == 0 {
            let parts = s.components(separatedBy: ",")
            s = (parts.count == 2 && parts[1].count == 3)
                ? s.replacingOccurrences(of: ",", with: "")        // "25,000" thousands
                : s.replacingOccurrences(of: ",", with: ".")       // "4,50" EU decimal
        } else if commas > 1 {
            s = s.replacingOccurrences(of: ",", with: "")          // "1,234,567"
        }
        return Double(s)
    }

    // MARK: - Name cleaning

    private static func cleanName(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespaces)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "$£€¥฿₫₩ "))
        s = s.replacingOccurrences(of: #"^\d+\s*[xX×]\s*"#, with: "", options: .regularExpression)
        // Strip trailing standalone quantity (e.g. "Latte Large 1" → "Latte Large")
        s = s.replacingOccurrences(of: #"\s+\d{1,2}$"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[\.\-_\s]{3,}$"#, with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Summary detection

    private static let summaryPrefixes = [
        // Totals
        "total", "subtotal", "sub-total", "sub total", "grand total",
        // Taxes / fees
        "tax", "vat", "gst", "hst", "pst", "sales tax",
        "tip", "gratuity", "service charge", "service fee",
        "discount", "savings",
        // Payment
        "cash", "change", "balance", "batance", "baiance",
        "amount", "credit", "debit", "payment",
        // Date / time
        "date", "time", "t-in", "t-out",
        // Contact / address
        "address", "adress", "tel:", "phone:", "fax:", "email:",
        "www.", "http",
        // Receipt metadata
        "invoice", "receipt no", "order no", "ref.",
        "exchange", "rate:",
        // Table / staff (column headers and section labels)
        "cashier", "pax", "dine in", "dine out",
        "qt", "qty", "quantity",
        "unit price", "unit cost",
        "description", "item",
        // Closing
        "thank you", "thank",
    ]

    private static func isSummaryLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return summaryPrefixes.contains { prefix in
            guard lower.hasPrefix(prefix) else { return false }
            // Require a word boundary after the prefix so "cash" doesn't match "cashreceipt"
            let afterIdx = lower.index(lower.startIndex, offsetBy: prefix.count)
            if afterIdx == lower.endIndex { return true }
            return !lower[afterIdx].isLetter
        }
    }

    // MARK: - Date extraction

    private static let dateFormats = [
        "MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd", "yyyy/MM/dd",
        "MM-dd-yyyy", "dd-MM-yyyy", "MM/dd/yy", "dd/MM/yy",
        "MMM dd, yyyy", "dd MMM yyyy", "d MMM yyyy",
    ]

    private static func extractDate(from line: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let tokens = [line] + line.components(separatedBy: .whitespaces)
        for format in dateFormats {
            formatter.dateFormat = format
            for token in tokens {
                if let date = formatter.date(from: token) { return date }
            }
        }
        return nil
    }

    // MARK: - Category inference

    private static let categoryMap: [(keywords: [String], category: Category)] = [
        (["coffee", "tea", "latte", "espresso", "cappuccino", "americano",
          "juice", "water", "soda", "beer", "wine", "beverage", "smoothie",
          "drink", "cola", "pepsi", "sprite", "កាហ្វេ", "ទឹក"], .Drink),
        (["sandwich", "burger", "pizza", "salad", "soup", "rice", "noodle",
          "chicken", "beef", "pork", "fish", "bread", "cake", "cookie",
          "snack", "fries", "taco", "sushi", "pasta", "meal", "food",
          "lunch", "dinner", "breakfast", "បាយ", "នំ", "មាន់"], .food),
        (["uber", "lyft", "taxi", "bus", "train", "metro", "subway",
          "fuel", "gas", "parking", "toll", "fare", "flight"], .travel),
        (["medicine", "pharmacy", "clinic", "hospital",
          "vitamin", "dental", "doctor", "prescription"], .health),
        (["movie", "cinema", "concert", "game", "sport",
          "netflix", "spotify", "ticket", "show"], .entertainment),
    ]

    private static func inferCategory(from name: String) -> String {
        let lower = name.lowercased()
        for (keywords, category) in categoryMap {
            if keywords.contains(where: { lower.contains($0) }) { return category.rawValue }
        }
        return Category.utilities.rawValue
    }
}
