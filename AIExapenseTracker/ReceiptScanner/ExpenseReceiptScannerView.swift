//
//  ExpenseReceiptScannerView.swift
//  AIExpenseTracker
//
//  Created by Alfian Losari on 07/07/24.
//

import AIReceiptScanner
import SwiftUI

struct ExpenseReceiptScannerView: View {
    @State var scanStatus: ScanStatus = .idle
    @State var addReceiptToExpenseSheetItem: SuccessScanResult?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            // Main Scanner View with enhanced UI
            VStack(spacing: 0) {
                // Status indicator with visual feedback
                VStack(spacing: 16) {
                    ScanStatusView(scanStatus: scanStatus, isProcessing: isProcessing)
                    
                    if case .idle = scanStatus {
                        WelcomePromptView()
                    }
                }
                .padding()
                
                // Show receipt image when available
                if let receiptImage = scanStatus.receiptImage {
                    receiptImage
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                        .frame(maxHeight: 300)
                }
                
                // Main scanner
                ReceiptPickerScannerView(apiKey: apiKey, scanStatus: $scanStatus)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(color: .blue.opacity(0.1), radius: 10, y: 5)
                    .opacity(scanStatus.receiptImage == nil ? 1 : 0.5) // Dim when showing result
                
                // Error message if failed
                if case .failure(let error, _) = scanStatus {
                    ErrorView(error: error) {
                        // Retry action - reset to idle
                        scanStatus = .idle
                    }
                    .padding()
                }
                
                // Tips Carousel
                if case .idle = scanStatus {
                    TipsCarouselView()
                        .padding()
                }
                
                Spacer()
            }
            
            // Success Animation Overlay
            if case .success = scanStatus {
                SuccessAnimationView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("📸 AI Receipt Scanner")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $addReceiptToExpenseSheetItem) {
            AddReceiptToExpenseConfirmationView(vm: .init(scanResult: $0))
                .frame(minWidth: horizontalSizeClass == .regular ? 960 : nil, minHeight: horizontalSizeClass == .regular ? 512 : nil)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let scanResult = scanStatus.scanResult {
                    SuccessActionButton(scanResult: scanResult) {
                        addReceiptToExpenseSheetItem = scanResult
                    }
                }
                
                if case .failure = scanStatus {
                    Button("Try Again") {
                        scanStatus = .idle
                    }
                }
            }
        }
        .onChange(of: scanStatus) { newStatus in
            handleScanStatusChange(newStatus)
        }
    }
    
    private func handleScanStatusChange(_ status: ScanStatus) {
        switch status {
        case .pickingImage, .prompting:
            isProcessing = true
        case .success:
            isProcessing = false
            playHapticFeedback()
        default:
            isProcessing = false
        }
    }
    
    private func playHapticFeedback() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

// MARK: - Supporting Views

struct ScanStatusView: View {
    let scanStatus: ScanStatus
    let isProcessing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
                .symbolEffect(.bounce, value: isProcessing)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor.opacity(0.1))
                .stroke(backgroundColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var iconName: String {
        switch scanStatus {
        case .idle: return "doc.viewfinder"
        case .pickingImage: return "photo.on.rectangle"
        case .prompting: return "wand.and.stars"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch scanStatus {
        case .idle: return .blue
        case .pickingImage: return .orange
        case .prompting: return .purple
        case .success: return .green
        case .failure: return .red
        }
    }
    
    private var backgroundColor: Color {
        switch scanStatus {
        case .idle: return .blue
        case .pickingImage: return .orange
        case .prompting: return .purple
        case .success: return .green
        case .failure: return .red
        }
    }
    
    private var statusTitle: String {
        switch scanStatus {
        case .idle: return "Ready to Scan"
        case .pickingImage: return "Selecting Image"
        case .prompting: return "AI is Analyzing"
        case .success: return "Receipt Scanned!"
        case .failure: return "Scan Failed"
        }
    }
    
    private var statusSubtitle: String {
        switch scanStatus {
        case .idle: return "Take a photo or select from gallery"
        case .pickingImage: return "Choosing receipt image..."
        case .prompting: return "Extracting items and amounts..."
        case .success: return "Ready to add to expenses"
        case .failure: return "Please try again with a clearer image"
        }
    }
}

struct WelcomePromptView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Smart Expense Tracking")
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            
            Text("Snap a receipt → AI extracts details → Add to expenses")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
}

struct TipsCarouselView: View {
    let tips = [
        ("📱", "Hold phone steady for best results"),
        ("💡", "Good lighting improves accuracy"),
        ("📄", "Make sure receipt is flat"),
        ("🔍", "Include all items and totals"),
        ("⚡", "Process multiple receipts quickly")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tips, id: \.0) { emoji, tip in
                    HStack(spacing: 8) {
                        Text(emoji)
                            .font(.title3)
                        Text(tip)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.08))
                    )
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SuccessAnimationView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 200, height: 200)
                .scaleEffect(animate ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 1).repeatCount(3, autoreverses: true), value: animate)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.3), radius: 10)
        }
        .onAppear {
            animate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                animate = false
            }
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Scan Failed")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.05))
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SuccessActionButton: View {
    let scanResult: SuccessScanResult
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add \(scanResult.receipt.items?.count ?? 0) Items")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.green.gradient)
            )
            .foregroundColor(.white)
            .shadow(color: .green.opacity(0.3), radius: 5)
        }
        .buttonStyle(.plain)
    }
}
