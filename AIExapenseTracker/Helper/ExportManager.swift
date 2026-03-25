//
//  ExportManager.swift
//  AIExapenseTracker
//
//  Generates exportable representations of expense logs (CSV, PDF, plain text).
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ExportManager {

    // MARK: - CSV

    /// Writes a CSV file to the temp directory and returns its URL.
    static func csvURL(from logs: [ExpenseLog]) -> URL {
        let csv = csvString(from: logs)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("expenses_\(dateStamp()).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func csvString(from logs: [ExpenseLog]) -> String {
        var lines = ["Name,Category,Amount,Currency,Date"]
        for log in logs {
            let name     = log.name.replacingOccurrences(of: "\"", with: "\"\"")
            let category = log.category.replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\"\(name)\",\"\(category)\",\(log.amount),\(log.currency),\(log.dateText)")
        }

        // Summary footer
        let total    = logs.reduce(0) { $0 + $1.amount }
        let currency = logs.first?.currency ?? "USD"
        lines.append("")   // blank separator row
        lines.append("\"Total:\",\"\",\(String(format: "%.2f", total)),\"\(currency)\",\"(\(logs.count) items)\"")

        return lines.joined(separator: "\n")
    }

    // MARK: - PDF

    /// Renders a styled PDF and returns its temp-directory URL.
    static func pdfURL(from logs: [ExpenseLog]) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("expenses_\(dateStamp()).pdf")

#if canImport(UIKit)
        // A4 page: 595 × 842 pt
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            let margin: CGFloat = 40
            let colWidths: [CGFloat] = [180, 100, 80, 60, 100]  // Name, Category, Amount, Currency, Date
            let rowHeight: CGFloat   = 22
            let headerHeight: CGFloat = 60
            var cursorY: CGFloat     = 0

            // ── Paragraph styles ──────────────────────────────────────────
            let centerStyle = NSMutableParagraphStyle()
            centerStyle.alignment = .center

            let leftStyle = NSMutableParagraphStyle()
            leftStyle.alignment = .left

            let rightStyle = NSMutableParagraphStyle()
            rightStyle.alignment = .right

            // ── Fonts & colors ────────────────────────────────────────────
            let titleFont    = UIFont.boldSystemFont(ofSize: 18)
            let subtitleFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let headerFont   = UIFont.boldSystemFont(ofSize: 10)
            let cellFont     = UIFont.systemFont(ofSize: 9)
            let totalFont    = UIFont.boldSystemFont(ofSize: 10)
            let accentColor  = UIColor.systemBlue
            let rowAlt       = UIColor.systemGray6
            let headerBG     = accentColor.withAlphaComponent(0.12)

            // ── Column definitions ────────────────────────────────────────
            let colTitles = ["Name", "Category", "Amount", "Currency", "Date"]
            let colAligns: [NSTextAlignment] = [.left, .left, .right, .center, .center]

            func colX(_ index: Int) -> CGFloat {
                margin + colWidths[0..<index].reduce(0, +)
            }

            // ── Helper: new page ──────────────────────────────────────────
            func beginPage() {
                ctx.beginPage()
                cursorY = margin
            }

            // ── Helper: draw one row ──────────────────────────────────────
            func drawRow(
                values: [String],
                y: CGFloat,
                font: UIFont,
                bgColor: UIColor?,
                textColor: UIColor = .black
            ) {
                if let bg = bgColor {
                    bg.setFill()
                    UIRectFill(CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: rowHeight))
                }
                for (i, value) in values.enumerated() {
                    let align = i < colAligns.count ? colAligns[i] : .left
                    let para = NSMutableParagraphStyle()
                    para.alignment = align
                    para.lineBreakMode = .byTruncatingTail
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: textColor,
                        .paragraphStyle: para
                    ]
                    let padding: CGFloat = 4
                    let rect = CGRect(x: colX(i) + padding, y: y + 4, width: colWidths[i] - padding * 2, height: rowHeight - 4)
                    value.draw(in: rect, withAttributes: attrs)
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // PAGE 1 — header block
            // ═══════════════════════════════════════════════════════════════
            beginPage()

            // Title bar background
            accentColor.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: pageRect.width, height: headerHeight))

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white,
                .paragraphStyle: centerStyle
            ]
            "Expense Report".draw(
                in: CGRect(x: margin, y: 14, width: pageRect.width - margin * 2, height: 28),
                withAttributes: titleAttrs
            )

            // Subtitle (date)
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85),
                .paragraphStyle: centerStyle
            ]
            "Generated \(dateStamp(formatted: true))".draw(
                in: CGRect(x: margin, y: 38, width: pageRect.width - margin * 2, height: 18),
                withAttributes: subAttrs
            )

            cursorY = headerHeight + 16

            // ── Column header row ─────────────────────────────────────────
            headerBG.setFill()
            UIRectFill(CGRect(x: margin, y: cursorY, width: pageRect.width - margin * 2, height: rowHeight))

            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: accentColor
            ]
            for (i, title) in colTitles.enumerated() {
                let para = NSMutableParagraphStyle()
                para.alignment = colAligns[i]
                var attrs = headerAttrs
                attrs[.paragraphStyle] = para
                let padding: CGFloat = 4
                title.draw(
                    in: CGRect(x: colX(i) + padding, y: cursorY + 5, width: colWidths[i] - padding * 2, height: rowHeight - 6),
                    withAttributes: attrs
                )
            }
            cursorY += rowHeight

            // Divider under header
            accentColor.withAlphaComponent(0.4).setFill()
            UIRectFill(CGRect(x: margin, y: cursorY, width: pageRect.width - margin * 2, height: 1))
            cursorY += 2

            // ── Data rows ─────────────────────────────────────────────────
            let bottomMargin: CGFloat = margin + rowHeight + 16  // reserve space for total row
            for (idx, log) in logs.enumerated() {
                if cursorY + rowHeight > pageRect.height - bottomMargin {
                    // New page — repeat column header
                    beginPage()
                    headerBG.setFill()
                    UIRectFill(CGRect(x: margin, y: cursorY, width: pageRect.width - margin * 2, height: rowHeight))
                    for (i, title) in colTitles.enumerated() {
                        let para = NSMutableParagraphStyle()
                        para.alignment = colAligns[i]
                        var attrs = headerAttrs
                        attrs[.paragraphStyle] = para
                        let padding: CGFloat = 4
                        title.draw(
                            in: CGRect(x: colX(i) + padding, y: cursorY + 5, width: colWidths[i] - padding * 2, height: rowHeight - 6),
                            withAttributes: attrs
                        )
                    }
                    cursorY += rowHeight
                    accentColor.withAlphaComponent(0.4).setFill()
                    UIRectFill(CGRect(x: margin, y: cursorY, width: pageRect.width - margin * 2, height: 1))
                    cursorY += 2
                }

                let bg: UIColor? = idx.isMultiple(of: 2) ? nil : rowAlt
                drawRow(
                    values: [log.name, log.category, String(format: "%.2f", log.amount), log.currency, log.dateText],
                    y: cursorY,
                    font: cellFont,
                    bgColor: bg
                )
                cursorY += rowHeight
            }

            // ── Total row ─────────────────────────────────────────────────
            let total    = logs.reduce(0) { $0 + $1.amount }
            let currency = logs.first?.currency ?? "USD"
            cursorY += 4

            accentColor.withAlphaComponent(0.4).setFill()
            UIRectFill(CGRect(x: margin, y: cursorY, width: pageRect.width - margin * 2, height: 1))
            cursorY += 4

            drawRow(
                values: [
                    "Total: \(String(format: "%.2f", total)) \(currency)  (\(logs.count) items)",
                    "", "", "", ""
                ],
                y: cursorY,
                font: totalFont,
                bgColor: accentColor.withAlphaComponent(0.08),
                textColor: accentColor
            )
        }

        try? data.write(to: url)
#endif
        return url
    }

    // MARK: - Plain Text

    static func plainText(from logs: [ExpenseLog]) -> String {
        guard !logs.isEmpty else { return "No expenses found." }
        var lines = ["=== Expense Report (\(dateStamp(formatted: true))) ===", ""]
        for log in logs {
            lines.append("• \(log.name)")
            lines.append("  \(log.amountText)  ·  \(log.category)  ·  \(log.dateText)")
        }
        let total    = logs.reduce(0) { $0 + $1.amount }
        let currency = logs.first?.currency ?? "USD"
        lines.append("")
        lines.append("Total: \(String(format: "%.2f", total)) \(currency)  (\(logs.count) items)")
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func dateStamp(formatted: Bool = false) -> String {
        let f = DateFormatter()
        f.dateFormat = formatted ? "yyyy-MM-dd" : "yyyyMMdd_HHmmss"
        return f.string(from: Date())
    }
}
