// HistoryLifecycleTests.swift
// MikaScreenSnapTests
//
// The path that carried the heaviest finding of the reconstruction: auto-save runs before
// the editor opens, so the file on disk is the untouched original. These exercise the real
// filesystem — write, replace, delete — rather than reasoning about it.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class HistoryLifecycleTests: XCTestCase {

    private var directory: URL!
    private var preferences: AppPreferences!
    private var history: ScreenshotHistoryManager!

    override func setUp() async throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MikaHistoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        preferences = AppPreferences()
        preferences.saveLocation = directory
        preferences.autoSaveEnabled = true
        preferences.imageFormat = .png
        history = ScreenshotHistoryManager(preferences: preferences)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func image(_ colour: NSColor, size: NSSize = NSSize(width: 40, height: 40)) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        colour.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }

    private func firstPixel(of url: URL) -> NSColor? {
        guard let image = NSImage(contentsOf: url),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return NSBitmapImageRep(cgImage: cg).colorAt(x: 1, y: 1)?.usingColorSpace(.sRGB)
    }

    func testAutoSaveWritesAFileAndReturnsIt() throws {
        let url = try XCTUnwrap(history.autoSave(image(.red)))

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(history.items.count, 1)
    }

    func testAutoSaveWritesNothingWhenDisabled() {
        preferences.autoSaveEnabled = false
        XCTAssertNil(history.autoSave(image(.red)))

        let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(files?.filter { $0.hasSuffix("png") }.count, 0)
    }

    /// The core of the finding: the file the editor exports must replace the original, not
    /// sit next to it.
    func testReplacingASavedCaptureOverwritesTheSameFile() throws {
        let url = try XCTUnwrap(history.autoSave(image(.red)))
        let before = try XCTUnwrap(firstPixel(of: url))
        XCTAssertGreaterThan(before.redComponent, 0.9, "control: the original is red")

        history.replaceSaved(at: url, with: image(.blue))

        let after = try XCTUnwrap(firstPixel(of: url))
        XCTAssertGreaterThan(after.blueComponent, 0.9, "the file still holds the original image")
        XCTAssertLessThan(after.redComponent, 0.1)

        let pngs = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix("png") }
        XCTAssertEqual(pngs.count, 1, "replacing must not leave a second file behind")
    }

    func testReplacingKeepsTheHistoryEntryAndItsIdentity() throws {
        let url = try XCTUnwrap(history.autoSave(image(.red)))
        let idBefore = history.items[0].id

        history.replaceSaved(at: url, with: image(.blue))

        XCTAssertEqual(history.items.count, 1)
        XCTAssertEqual(history.items[0].id, idBefore, "the entry should be updated, not duplicated")
    }

    func testTwoCapturesInQuickSuccessionBothSurvive() throws {
        let first = try XCTUnwrap(history.autoSave(image(.red)))
        let second = try XCTUnwrap(history.autoSave(image(.green)))

        XCTAssertNotEqual(first, second)
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))
        XCTAssertEqual(history.items.count, 2)
    }

    func testDeletingAnItemRemovesFileAndThumbnail() throws {
        _ = try XCTUnwrap(history.autoSave(image(.red)))
        let item = history.items[0]

        history.deleteItem(item)

        XCTAssertFalse(FileManager.default.fileExists(atPath: item.url.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: item.thumbnailURL.path))
        XCTAssertEqual(history.items.count, 0)
    }

    /// Files that were never loaded used to survive "Clear History" while the user was told
    /// everything had been deleted.
    func testClearAllRemovesFilesItNeverLoaded() throws {
        _ = history.autoSave(image(.red))

        let stray = directory.appendingPathComponent("dropped-in-by-hand.png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: stray)

        history.clearAll()

        XCTAssertFalse(FileManager.default.fileExists(atPath: stray.path),
                       "a file in the folder survived Clear History")
        XCTAssertEqual(history.items.count, 0)
    }

    func testStorageUsageCountsThumbnailsAsWell() throws {
        _ = try XCTUnwrap(history.autoSave(image(.red, size: NSSize(width: 400, height: 400))))
        let item = history.items[0]

        let originalSize = (try FileManager.default.attributesOfItem(atPath: item.url.path)[.size] as? Int64) ?? 0
        XCTAssertGreaterThan(history.storageUsage(), originalSize,
                             "thumbnails are missing from the reported figure")
    }

    func testJpegFormatIsHonouredOnSave() throws {
        preferences.imageFormat = .jpeg
        let url = try XCTUnwrap(history.autoSave(image(.red)))
        XCTAssertEqual(url.pathExtension, "jpg")
    }
}
