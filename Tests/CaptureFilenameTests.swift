// CaptureFilenameTests.swift
// MikaScreenSnapTests
//
// Capture filenames used to carry only second precision and were written without checking
// for an existing file, so two captures inside the same second left one of them behind.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class CaptureFilenameTests: XCTestCase {

    private var directory: URL!

    override func setUp() async throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MikaScreenSnapTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testTwoCapturesInTheSameSecondGetDifferentNames() {
        let prefs = AppPreferences()

        let first = prefs.uniqueCaptureURL(in: directory)
        FileManager.default.createFile(atPath: first.path, contents: Data())
        let second = prefs.uniqueCaptureURL(in: directory)

        XCTAssertNotEqual(first, second, "the second capture would have overwritten the first")
    }

    func testNamesKeepBeingUniqueUnderRepetition() {
        let prefs = AppPreferences()
        var seen = Set<String>()

        for _ in 0..<25 {
            let url = prefs.uniqueCaptureURL(in: directory)
            XCTAssertTrue(seen.insert(url.lastPathComponent).inserted, "duplicate name: \(url.lastPathComponent)")
            FileManager.default.createFile(atPath: url.path, contents: Data())
        }
    }

    func testExtensionFollowsTheConfiguredFormat() {
        let prefs = AppPreferences()

        prefs.imageFormat = .png
        XCTAssertEqual(prefs.uniqueCaptureURL(in: directory).pathExtension, "png")

        prefs.imageFormat = .jpeg
        XCTAssertEqual(prefs.uniqueCaptureURL(in: directory).pathExtension, "jpg")
    }

    func testTimestampIsIndependentOfTheUsersLocale() {
        // A non-Gregorian calendar in the user's locale used to be able to produce a name
        // that no longer sorts or parses as expected.
        let prefs = AppPreferences()
        let name = prefs.uniqueCaptureURL(in: directory).lastPathComponent

        XCTAssertTrue(name.hasPrefix("MikaSnap_"))
        let stamp = name.dropFirst("MikaSnap_".count).prefix(23)
        XCTAssertNotNil(stamp.range(of: #"^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}-\d{3}"#, options: .regularExpression),
                        "unexpected timestamp shape: \(stamp)")
    }

    func testResetListCoversEveryKeyTheAppWrites() {
        // The reset list is hand-maintained; colour history used to be missing from it and
        // therefore survived "Reset All Preferences".
        XCTAssertTrue(AppPreferences.ownedDefaultsKeys.contains(ColorHistoryManager.historyDefaultsKey))
        XCTAssertTrue(AppPreferences.ownedDefaultsKeys.contains(ColorHistoryManager.paletteDefaultsKey))
        XCTAssertTrue(AppPreferences.ownedDefaultsKeys.contains("hotkeyBindings"))
        XCTAssertTrue(AppPreferences.ownedDefaultsKeys.contains("excludedBundleIdentifiers"))
    }

    func testDefaultStrokeWidthIsOneOfTheOfferedChoices() {
        // The default used to be 3 while Preferences offered 2, 4 and 6 — so the picker
        // opened with nothing selected.
        let prefs = AppPreferences()
        XCTAssertTrue([2.0, 4.0, 6.0].contains(prefs.defaultStrokeWidth),
                      "default \(prefs.defaultStrokeWidth) is not selectable in Preferences")
    }
}
