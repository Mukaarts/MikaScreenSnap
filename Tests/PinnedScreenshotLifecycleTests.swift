// PinnedScreenshotLifecycleTests.swift
// MikaScreenSnapTests
//
// Closing a pin used to only hide the window: the PNG stayed in Application Support
// forever, and because restoration sorted filenames ascending it brought back the *oldest*
// twenty — so a deliberately closed pin could reappear. These exercise the real files.
//
// `persistenceDirOverride` keeps all of this inside a temporary directory.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class PinnedScreenshotLifecycleTests: XCTestCase {

    private var directory: URL!

    override func setUp() async throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MikaPinTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        PinnedScreenshotManager.persistenceDirOverride = directory
    }

    override func tearDown() async throws {
        PinnedScreenshotManager.persistenceDirOverride = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 30, height: 30))
        image.lockFocus()
        NSColor.orange.setFill()
        NSRect(x: 0, y: 0, width: 30, height: 30).fill()
        image.unlockFocus()
        return image
    }

    private var storedFiles: [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: directory.path))?
            .filter { $0.hasSuffix("png") }.sorted() ?? []
    }

    func testPinningWritesExactlyOneFile() {
        let state = AppState()
        _ = PinnedScreenshotManager.pinImage(image(), appState: state)

        XCTAssertEqual(storedFiles.count, 1)
        XCTAssertEqual(state.pinnedPanels.count, 1)

        PinnedScreenshotManager.unpinAll(appState: state)
    }

    /// The finding itself.
    func testClosingAPinDeletesItsFile() throws {
        let state = AppState()
        let panel = try XCTUnwrap(PinnedScreenshotManager.pinImage(image(), appState: state))
        XCTAssertEqual(storedFiles.count, 1)

        PinnedScreenshotManager.unpinPanel(panel, appState: state)

        XCTAssertEqual(storedFiles.count, 0, "the closed pin left its image behind")
        XCTAssertEqual(state.pinnedPanels.count, 0)
    }

    func testCloseAllDeletesEveryFile() {
        let state = AppState()
        for _ in 0..<3 { _ = PinnedScreenshotManager.pinImage(image(), appState: state) }
        XCTAssertEqual(storedFiles.count, 3)

        PinnedScreenshotManager.unpinAll(appState: state)

        XCTAssertEqual(storedFiles.count, 0)
        XCTAssertEqual(state.pinnedPanels.count, 0)
    }

    func testPinsDoNotAccumulateAcrossOpenAndClose() {
        let state = AppState()
        for _ in 0..<5 {
            if let panel = PinnedScreenshotManager.pinImage(image(), appState: state) {
                PinnedScreenshotManager.unpinPanel(panel, appState: state)
            }
        }
        XCTAssertEqual(storedFiles.count, 0, "pinning and closing five times left files behind")
    }

    /// Restoration must take the newest, and must not leave the rest lying around.
    func testRestoreKeepsTheNewestAndRemovesTheSurplus() throws {
        for index in 0..<(PinnedScreenshotManager.maxPins + 5) {
            let name = String(format: "pin_2026-08-25_10-00-%02d-000.png", index)
            let url = directory.appendingPathComponent(name)
            let data = try XCTUnwrap(NSBitmapImageRep(
                data: XCTUnwrap(image().tiffRepresentation))?.representation(using: .png, properties: [:]))
            try data.write(to: url)
        }
        XCTAssertEqual(storedFiles.count, PinnedScreenshotManager.maxPins + 5)

        let state = AppState()
        PinnedScreenshotManager.restorePins(appState: state)

        XCTAssertEqual(state.pinnedPanels.count, PinnedScreenshotManager.maxPins)
        XCTAssertEqual(storedFiles.count, PinnedScreenshotManager.maxPins,
                       "files beyond the limit can never be restored and must not linger")

        // The newest are the ones with the highest seconds in the name.
        XCTAssertTrue(storedFiles.contains("pin_2026-08-25_10-00-24-000.png"), "newest was dropped")
        XCTAssertFalse(storedFiles.contains("pin_2026-08-25_10-00-00-000.png"), "oldest was kept")

        PinnedScreenshotManager.unpinAll(appState: state)
    }

    func testStorageUsageReportsWhatIsOnDisk() {
        let state = AppState()
        XCTAssertEqual(PinnedScreenshotManager.storageUsage(), 0)

        _ = PinnedScreenshotManager.pinImage(image(), appState: state)
        XCTAssertGreaterThan(PinnedScreenshotManager.storageUsage(), 0)

        PinnedScreenshotManager.clearAll(appState: state)
        XCTAssertEqual(PinnedScreenshotManager.storageUsage(), 0)
    }

    func testTheLimitIsEnforced() {
        let state = AppState()
        for _ in 0..<(PinnedScreenshotManager.maxPins + 3) {
            _ = PinnedScreenshotManager.pinImage(image(), appState: state)
        }
        XCTAssertEqual(state.pinnedPanels.count, PinnedScreenshotManager.maxPins)

        PinnedScreenshotManager.unpinAll(appState: state)
    }
}
