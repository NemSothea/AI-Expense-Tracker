//
//  ExpenseReceiptScannerView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 21/10/25.
//

import AIReceiptScanner
import SwiftUI

struct ExpenseReceiptScannerView: View {
    
    @State var scanStatus: ScanStatus = .idle
    @State var addReceiptToExpenseSheetItem: SuccessScanResult?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ReceiptPickerScannerView(apiKey: aiExpenseKey, scanStatus: $scanStatus)
            .sheet(item: $addReceiptToExpenseSheetItem) {
                AddReceiptToExpenseConfirmationView(vm: .init(scanResult: $0))
                    .frame(minWidth: horizontalSizeClass == .regular ? 960 : nil, minHeight: horizontalSizeClass == .regular ? 512 : nil)
            }
            .navigationTitle("AI Receipt Scanner")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if let scanResult = scanStatus.scanResult {
                        Button {
                            addReceiptToExpenseSheetItem = scanResult
                        } label: {
                            #if os(macOS)
                            HStack {
                                Image(systemName: "plus")
                                    .symbolRenderingMode(.monochrome)
                                    .tint(.accentColor)
                                Text("Add to Expesnes")
                            }
                            #else
                            Text("Add to Expenses")
                            #endif
                        }
                    }
                }
            }
    }
}

//#Preview {
//    ExpenseReceiptScannerView()
//}
