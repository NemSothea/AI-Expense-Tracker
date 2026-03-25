//
//  VisionReceiptScannerView.swift
//  AIExapenseTracker
//
//  Receipt scanner powered by Apple Vision — free, on-device, no API key.
//

import PhotosUI
import SwiftUI

struct VisionReceiptScannerView: View {

    @State private var vm = VisionReceiptScannerViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var confirmationItem: VisionScanResult?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject private var lm = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            statusHeader
                .padding([.horizontal, .top])
                .padding(.bottom, 8)

            if let preview = vm.previewImage {
                preview
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.12), radius: 6)
                    .frame(maxHeight: 280)
                    .padding(.bottom, 8)
            }

            if case .idle = vm.scanState {
                pickerSection
                tipsSection
                    .padding()
            }

            if case .success = vm.scanState {
                scanNewButton.padding(.top, 8)
            }

            if case .failure(let error) = vm.scanState {
                errorSection(error).padding()
            }

            Spacer()
        }
        .navigationTitle(lm.L(.scanReceipt))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if case .success(let result) = vm.scanState {
                    Button {
                        confirmationItem = result
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("\(lm.L(.addItemsPrefix)) \(result.receipt.items.count) \(lm.L(.scanItems))")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.green.gradient))
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $confirmationItem, onDismiss: fullReset) { result in
            VisionAddReceiptConfirmationView(vm: .init(scanResult: result))
                .frame(
                    minWidth: horizontalSizeClass == .regular ? 960 : nil,
                    minHeight: horizontalSizeClass == .regular ? 512 : nil
                )
        }
        #if os(iOS)
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        #endif
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task { await vm.scan(from: newItem) }
        }
        .onChange(of: cameraImage) { _, image in
            guard let image else { return }
            Task { await vm.scan(from: image) }
        }
    }

    // MARK: - Status header

    private var statusHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: stateIcon)
                .font(.title2)
                .foregroundColor(stateColor)
                .symbolEffect(.bounce, value: isProcessing)

            VStack(alignment: .leading, spacing: 3) {
                Text(stateTitle)
                    .font(.subheadline).fontWeight(.medium)
                Text(stateSubtitle)
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            if isProcessing {
                ProgressView().scaleEffect(0.85)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(stateColor.opacity(0.08))
                .stroke(stateColor.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Reset

    private func fullReset() {
        vm.reset()
        selectedPhoto = nil
        cameraImage = nil
    }

    private var scanNewButton: some View {
        Button(action: fullReset) {
            Label(lm.L(.scanNewReceipt), systemImage: "arrow.clockwise")
                .font(.subheadline).fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().strokeBorder(Color.green, lineWidth: 1.5))
                .foregroundColor(.green)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Picker

    private var pickerSection: some View {
        VStack(spacing: 16) {
            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    cameraImage = nil
                    showCamera = true
                } label: {
                    Label(lm.L(.takePhoto), systemImage: "camera.fill")
                        .font(.headline)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 14)
                        .background(Color.orange.gradient)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.25), radius: 6)
                }
                .buttonStyle(.plain)
            }
            #endif

            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(lm.L(.chooseFromLibrary), systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(Color.blue.gradient)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.25), radius: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Error

    private func errorSection(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle).foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: fullReset) {
                Label(lm.L(.tryAgain), systemImage: "arrow.clockwise")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05))
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Tips

    private var tipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([
                    ("💡", lm.L(.tipGoodLighting)),
                    ("📄", lm.L(.tipFlatReceipt)),
                    ("🔍", lm.L(.tipFullReceipt)),
                    ("⚡", lm.L(.tipFreeNoKey))
                ], id: \.0) { emoji, tip in
                    HStack(spacing: 6) {
                        Text(emoji)
                        Text(tip).font(.caption).fontWeight(.medium)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.blue.opacity(0.08)))
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - State helpers

    private var isProcessing: Bool {
        switch vm.scanState {
        case .loadingImage, .scanning: return true
        default: return false
        }
    }

    private var stateIcon: String {
        switch vm.scanState {
        case .idle:         return "doc.viewfinder"
        case .loadingImage: return "photo.on.rectangle"
        case .scanning:     return "text.viewfinder"
        case .success:      return "checkmark.circle.fill"
        case .failure:      return "exclamationmark.triangle.fill"
        }
    }

    private var stateColor: Color {
        switch vm.scanState {
        case .idle:         return .blue
        case .loadingImage: return .orange
        case .scanning:     return .purple
        case .success:      return .green
        case .failure:      return .red
        }
    }

    @MainActor private var stateTitle: String {
        switch vm.scanState {
        case .idle:                 return lm.L(.readyToScan)
        case .loadingImage:         return lm.L(.loadingImage)
        case .scanning:             return lm.L(.readingText)
        case .success(let result):  return "\(result.receipt.items.count) \(lm.L(.scanItems)) \(lm.L(.foundSuffix))"
        case .failure:              return lm.L(.scanFailed)
        }
    }

    @MainActor private var stateSubtitle: String {
        switch vm.scanState {
        case .idle:         return lm.L(.scanReadyHint)
        case .loadingImage: return lm.L(.scanLoadingHint)
        case .scanning:     return lm.L(.scanScanningHint)
        case .success:      return lm.L(.scanSuccessHint)
        case .failure:      return lm.L(.scanFailedHint)
        }
    }
}
