// OCREngine.swift
// MikaScreenSnap
//
// Text recognition using Apple Vision framework.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
@preconcurrency import Vision

enum OCREngine {
    static func recognizeText(in cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["de", "en", "fr"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
