// RedactionStrengthTests.swift
// MikaScreenSnapTests
//
// Redaction is a privacy promise, so its strength has to scale with the region it covers:
// a fixed pixel radius hides less the larger the image.

import XCTest
@testable import MikaScreenSnap

@MainActor
final class RedactionStrengthTests: XCTestCase {

    func testBlurRadiusGrowsWithTheRegion() {
        let small = BlurAnnotation.radius(for: CGRect(x: 0, y: 0, width: 60, height: 60))
        let large = BlurAnnotation.radius(for: CGRect(x: 0, y: 0, width: 600, height: 600))

        XCTAssertGreaterThan(large, small)
    }

    func testBlurRadiusNeverDropsBelowTheFloor() {
        let tiny = BlurAnnotation.radius(for: CGRect(x: 0, y: 0, width: 4, height: 4))
        XCTAssertGreaterThanOrEqual(tiny, 15.0)
    }

    func testBlurRadiusFollowsTheShorterSide() {
        // A wide, flat region must not be judged by its width — the text inside it is only
        // as tall as the short side.
        let wide = BlurAnnotation.radius(for: CGRect(x: 0, y: 0, width: 1000, height: 40))
        let square = BlurAnnotation.radius(for: CGRect(x: 0, y: 0, width: 40, height: 40))

        XCTAssertEqual(wide, square)
    }

    func testPixelateBlockSizeGrowsWithTheRegion() {
        let small = PixelateAnnotation.blockSize(for: CGRect(x: 0, y: 0, width: 60, height: 60))
        let large = PixelateAnnotation.blockSize(for: CGRect(x: 0, y: 0, width: 600, height: 600))

        XCTAssertGreaterThan(large, small)
    }

    func testPixelateBlockSizeNeverDropsBelowTheFloor() {
        let tiny = PixelateAnnotation.blockSize(for: CGRect(x: 0, y: 0, width: 4, height: 4))
        XCTAssertGreaterThanOrEqual(tiny, 10.0)
    }

    func testResizingARedactionRecomputesItsStrength() {
        let annotation = BlurAnnotation(rect: CGRect(x: 0, y: 0, width: 40, height: 40))
        let before = annotation.radius

        annotation.resized(
            from: CGRect(x: 0, y: 0, width: 40, height: 40),
            to: CGRect(x: 0, y: 0, width: 800, height: 800)
        )

        XCTAssertGreaterThan(annotation.radius, before,
                             "a region dragged larger must not keep its old, weaker blur")
    }
}
