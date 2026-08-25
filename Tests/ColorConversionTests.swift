// ColorConversionTests.swift
// MikaScreenSnapTests
//
// Hex, RGB and HSL conversion for the colour picker — arithmetic that is invisible until
// a copied value is wrong.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class ColorConversionTests: XCTestCase {

    func testPureRedConvertsToHexRgbAndHsl() {
        let color = PickedColor(nsColor: NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))

        XCTAssertEqual(color.hex, "#FF0000")
        XCTAssertEqual(color.rgb.r, 255)
        XCTAssertEqual(color.rgb.g, 0)
        XCTAssertEqual(color.rgb.b, 0)
        XCTAssertEqual(color.hsl.h, 0)
        XCTAssertEqual(color.hsl.s, 100)
        XCTAssertEqual(color.hsl.l, 50)
    }

    func testWhiteAndBlackHaveZeroSaturation() {
        let white = PickedColor(nsColor: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        let black = PickedColor(nsColor: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))

        XCTAssertEqual(white.hex, "#FFFFFF")
        XCTAssertEqual(white.hsl.s, 0)
        XCTAssertEqual(white.hsl.l, 100)

        XCTAssertEqual(black.hex, "#000000")
        XCTAssertEqual(black.hsl.s, 0)
        XCTAssertEqual(black.hsl.l, 0)
    }

    func testHexIsAlwaysSixUppercaseDigits() {
        let color = PickedColor(nsColor: NSColor(srgbRed: 0.0392, green: 0.0392, blue: 0.0392, alpha: 1))

        XCTAssertEqual(color.hex.count, 7, "leading zeroes must be padded, not dropped")
        XCTAssertEqual(color.hex, color.hex.uppercased())
    }

    func testBrandTealSurvivesAHexRoundTrip() {
        let original = "#1D9E75"
        let color = PickedColor(nsColor: ColorHistoryManager.colorFromHex(original))
        XCTAssertEqual(color.hex, original)
    }

    func testColorFromHexAcceptsALeadingHash() {
        let withHash = ColorHistoryManager.colorFromHex("#5DCAA5")
        let without = ColorHistoryManager.colorFromHex("5DCAA5")

        XCTAssertEqual(PickedColor(nsColor: withHash).hex, PickedColor(nsColor: without).hex)
    }
}
