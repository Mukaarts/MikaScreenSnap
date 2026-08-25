// RedactionEffectivenessTests.swift
// MikaScreenSnapTests
//
// The question redaction actually has to answer: after blurring or pixelating a region,
// is the text inside it still readable? This renders text, redacts it, and puts Apple's
// text recognition on the result. If Vision still reads it, the redaction is not one.
//
// The app already ships the recogniser (B05), so this is a real measurement rather than
// an eyeball check.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class RedactionEffectivenessTests: XCTestCase {

    private let secret = "SwordfishHunter2026"

    /// Draws the secret onto a white background at a realistic on-screen size.
    private func imageWithSecret(fontSize: CGFloat = 42) -> NSImage {
        let size = NSSize(width: 700, height: 160)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        (secret as NSString).draw(
            at: NSPoint(x: 30, y: 55),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .regular),
                .foregroundColor: NSColor.black,
            ]
        )
        image.unlockFocus()
        return image
    }

    private func recognisedText(in image: NSImage) async throws -> String {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            XCTFail("could not convert image")
            return ""
        }
        return try await OCREngine.recognizeText(in: cg)
    }

    /// Control: without this passing, the other two prove nothing.
    func testTheSecretIsReadableBeforeRedaction() async throws {
        let text = try await recognisedText(in: imageWithSecret())
        XCTAssertTrue(text.contains("Swordfish"),
                      "control failed — recognition never saw the secret, so the redaction tests are meaningless. Got: \(text)")
    }

    func testBlurMakesTheSecretUnreadable() async throws {
        let base = imageWithSecret()
        guard let cg = base.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let region = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
        let annotation = BlurAnnotation(rect: region)

        guard let redacted = AnnotationRenderer.renderFinalImage(baseImage: base, annotations: [annotation]) else {
            XCTFail("render failed"); return
        }

        let text = try await recognisedText(in: redacted)
        XCTAssertFalse(text.contains("Swordfish"),
                       "blur left the secret readable: \(text)")
    }

    func testPixelateMakesTheSecretUnreadable() async throws {
        let base = imageWithSecret()
        guard let cg = base.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let region = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
        let annotation = PixelateAnnotation(rect: region)

        guard let redacted = AnnotationRenderer.renderFinalImage(baseImage: base, annotations: [annotation]) else {
            XCTFail("render failed"); return
        }

        let text = try await recognisedText(in: redacted)
        XCTAssertFalse(text.contains("Swordfish"),
                       "pixelation left the secret readable: \(text)")
    }

    /// The edge case that motivated the clamp: text sitting right at the border of the
    /// redacted region, where an unclamped blur mixes with transparent space and stays
    /// far sharper than the middle.
    func testTextAtTheEdgeOfTheRegionIsAlsoUnreadable() async throws {
        let base = imageWithSecret()
        guard let cg = base.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        // Cover the text but end the region just past the baseline, so the glyphs touch
        // the bottom edge of the redaction.
        let region = CGRect(x: 0, y: CGFloat(cg.height) * 0.30,
                            width: CGFloat(cg.width), height: CGFloat(cg.height) * 0.70)
        let annotation = BlurAnnotation(rect: region)

        guard let redacted = AnnotationRenderer.renderFinalImage(baseImage: base, annotations: [annotation]) else {
            XCTFail("render failed"); return
        }

        let text = try await recognisedText(in: redacted)
        XCTAssertFalse(text.contains("Swordfish"),
                       "the region's edge kept the secret readable: \(text)")
    }

    /// A redaction dragged larger has to strengthen with it, or a region resized up stays
    /// at the blur of its original, much smaller size.
    func testALargeRegionIsRedactedAsEffectivelyAsASmallOne() async throws {
        let base = imageWithSecret(fontSize: 96)
        guard let cg = base.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let region = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
        let annotation = PixelateAnnotation(rect: region)

        guard let redacted = AnnotationRenderer.renderFinalImage(baseImage: base, annotations: [annotation]) else {
            XCTFail("render failed"); return
        }

        let text = try await recognisedText(in: redacted)
        XCTAssertFalse(text.contains("Swordfish"),
                       "large text survived redaction: \(text)")
    }
}
