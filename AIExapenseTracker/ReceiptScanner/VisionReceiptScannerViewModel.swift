//
//  VisionReceiptScannerViewModel.swift
//  AIExapenseTracker
//
//  State machine for on-device receipt scanning via Apple Vision framework.
//

import Vision
import PhotosUI
import SwiftUI
import Observation

enum VisionScanState {
    case idle
    case loadingImage
    case scanning
    case success(VisionScanResult)
    case failure(Error)
}

@Observable
@MainActor
final class VisionReceiptScannerViewModel {

    var scanState: VisionScanState = .idle
    var previewImage: Image?
    /// Raw OCR output — visible in the UI so you can diagnose parse failures.
    var rawOCRLines: [String] = []

    // MARK: - Public API

    func scan(from item: PhotosPickerItem) async {
        scanState = .loadingImage
        previewImage = nil
        rawOCRLines = []
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                throw ScanError.imageLoadFailed
            }
            previewImage = Image(uiImage: uiImage)
            scanState = .scanning

            let lines = try await recognizeText(in: uiImage)
            rawOCRLines = lines

            let receipt = ReceiptTextParser.parse(lines: lines)
            if receipt.items.isEmpty {
                throw ScanError.noItemsFound(lines)
            }

            scanState = .success(VisionScanResult(receipt: receipt))
        } catch {
            scanState = .failure(error)
        }
    }

    func scan(from image: UIImage) async {
        scanState = .loadingImage
        previewImage = nil
        rawOCRLines = []
        previewImage = Image(uiImage: image)
        scanState = .scanning
        do {
            let lines = try await recognizeText(in: image)
            rawOCRLines = lines
            let receipt = ReceiptTextParser.parse(lines: lines)
            if receipt.items.isEmpty { throw ScanError.noItemsFound(lines) }
            scanState = .success(VisionScanResult(receipt: receipt))
        } catch {
            scanState = .failure(error)
        }
    }

    func reset() {
        scanState = .idle
        previewImage = nil
    }

    // MARK: - Vision OCR

    // Runs on a background thread — VNImageRequestHandler.perform() is synchronous
    // and would freeze the UI if called on the main actor.
    private func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { throw ScanError.imageLoadFailed }

        return try await Task.detached(priority: .userInitiated) {
            try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                        .compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: lines)
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false  // receipts have prices/codes the OS would "correct"

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }.value
    }

    // MARK: - Errors

    enum ScanError: LocalizedError {
        case imageLoadFailed
        case noItemsFound([String])

        var errorDescription: String? {
            switch self {
            case .imageLoadFailed:
                return "Could not load the selected image."
            case .noItemsFound(let lines):
                let preview = lines.prefix(6).joined(separator: "\n")
                return lines.isEmpty
                    ? "No text found. Make sure the receipt is well-lit and in focus."
                    : "Could not parse items. OCR detected:\n\n\(preview)"
            }
        }
    }
}
