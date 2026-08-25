// ScreenGeometryTests.swift
// MikaScreenSnapTests
//
// The coordinate maths behind area capture. This is the failure class that shipped twice:
// 3.4.1 fixed it for window captures while the area and full-screen paths kept computing
// against the wrong display — pure arithmetic that was never covered.

import XCTest
import AppKit
@testable import MikaScreenSnap

final class ScreenGeometryTests: XCTestCase {

    /// The primary display: AppKit origin and screen origin coincide.
    func testSourceRectOnPrimaryScreenFlipsYOnly() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let selection = CGRect(x: 100, y: 800, width: 400, height: 200)

        let result = ScreenGeometry.sourceRect(forAppKitRect: selection, inScreenFrame: screen)

        XCTAssertEqual(result.origin.x, 100)
        // 1080 - (800 + 200) = 80 from the top
        XCTAssertEqual(result.origin.y, 80)
        XCTAssertEqual(result.size, selection.size)
    }

    /// A second display to the right: the x offset has to come off as well.
    func testSourceRectOnScreenToTheRightSubtractsOrigin() {
        let screen = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
        let selection = CGRect(x: 2020, y: 1240, width: 300, height: 100)

        let result = ScreenGeometry.sourceRect(forAppKitRect: selection, inScreenFrame: screen)

        XCTAssertEqual(result.origin.x, 100, "x must be relative to the screen, not global")
        // 0 + 1440 - (1240 + 100) = 100
        XCTAssertEqual(result.origin.y, 100)
    }

    /// A display mounted above the primary one, so its AppKit origin is positive in y.
    func testSourceRectOnScreenAboveAccountsForOriginY() {
        let screen = CGRect(x: 0, y: 1080, width: 1920, height: 1080)
        let selection = CGRect(x: 0, y: 1080, width: 1920, height: 1080)

        let result = ScreenGeometry.sourceRect(forAppKitRect: selection, inScreenFrame: screen)

        XCTAssertEqual(result.origin, .zero, "a full-screen selection maps to the whole display")
        XCTAssertEqual(result.size, CGSize(width: 1920, height: 1080))
    }

    /// A display below the primary one has a negative AppKit origin.
    func testSourceRectOnScreenBelowHandlesNegativeOrigin() {
        let screen = CGRect(x: 0, y: -1080, width: 1920, height: 1080)
        let selection = CGRect(x: 10, y: -1080, width: 100, height: 80)

        let result = ScreenGeometry.sourceRect(forAppKitRect: selection, inScreenFrame: screen)

        XCTAssertEqual(result.origin.x, 10)
        // -1080 + 1080 - (-1080 + 80) = 1000
        XCTAssertEqual(result.origin.y, 1000)
    }

    /// Whatever the arrangement, the selection keeps its size.
    func testSourceRectPreservesSizeAcrossArrangements() {
        let selection = CGRect(x: 500, y: 500, width: 321, height: 123)
        let frames = [
            CGRect(x: 0, y: 0, width: 1920, height: 1080),
            CGRect(x: -1920, y: 0, width: 1920, height: 1080),
            CGRect(x: 1920, y: -300, width: 3840, height: 2160),
        ]

        for frame in frames {
            let result = ScreenGeometry.sourceRect(forAppKitRect: selection, inScreenFrame: frame)
            XCTAssertEqual(result.size, selection.size, "size changed for screen frame \(frame)")
        }
    }
}
