// AppStoreQAProbeTests.swift
// MikaScreenSnapTests
//
// Tests written by QA to pin down findings on feature 16. These document defects; they are
// not fixes. Failing ones are marked XCTExpectFailure with the finding number so the suite
// stays green while the defect stays visible.

import XCTest
@testable import MikaScreenSnap

@MainActor
final class AppStoreQAProbeTests: XCTestCase {

    /// Was BUG-04: the reset cleared the save-location bookmark but left onboarding marked
    /// complete, so nothing ever asked for a folder again. `resetAllPreferences` now
    /// reports whether setup has to run, and the caller acts on it — a flag alone was not
    /// enough, because it is read only at launch.
    func testResetReportsWhetherFirstRunSetupMustRunAgain() {
        let prefs = AppPreferences()
        let hadBookmark = prefs.saveLocationBookmark
        defer { prefs.saveLocationBookmark = hadBookmark }

        prefs.saveLocationBookmark = Data([0x01, 0x02])
        let needsSetupAgain = prefs.resetAllPreferences()

        XCTAssertNil(prefs.saveLocationBookmark, "reset clears the bookmark")

        // Outside a sandbox container — a test process, the direct build — there is no
        // folder to ask for, so setup must not be forced.
        XCTAssertFalse(needsSetupAgain)
        XCTAssertTrue(prefs.hasCompletedOnboarding)
        XCTAssertEqual(needsSetupAgain, !prefs.hasCompletedOnboarding,
                       "the return value and the flag must never disagree")
    }

    /// Was BUG-05: bookmark resolution had no test at all. The full set now lives in
    /// `SaveLocationStoreTests`; this is the corrupt-bookmark case.
    func testResolvingACorruptBookmarkReportsMissingRatherThanCrashing() {
        let prefs = AppPreferences()
        let hadBookmark = prefs.saveLocationBookmark
        defer { prefs.saveLocationBookmark = hadBookmark }

        prefs.saveLocationBookmark = Data("this is not a bookmark".utf8)

        // Outside a container the store falls back to the plain path, so this only proves
        // the call is survivable here. Under the sandbox it must yield .missing — that part
        // remains unproven and is recorded as such in the report.
        let result = SaveLocationStore.resolve(prefs)
        switch result {
        case .success, .failure:
            break  // must not trap
        }
    }

    /// The sandbox detection the whole save path hangs on. In a test process it must be
    /// false — if this ever flips, the plain-path fallback silently stops applying and the
    /// suite would test something other than what ships.
    func testTestProcessIsNotSandboxed() {
        XCTAssertFalse(SaveLocationStore.isSandboxed)
    }
}

// MARK: - Regressions from the BUG-01 fix

/// Second QA round: the fix for BUG-01 changed `deleteItem` from "always drop the entry"
/// to "drop it only if removal succeeded". That is right when the folder is gone — and
/// wrong when the file simply is not there any more.
@MainActor
final class DeleteAfterExternalRemovalTests: XCTestCase {

    /// Was BUG-07: a capture deleted in the Finder could no longer be cleared from the
    /// history, because `removeItem` threw "no such file" and the bracket reported failure.
    /// Deleting has three outcomes and only two are failures — this pins the third down.
    func testEntryCanStillBeRemovedAfterTheFileVanishedExternally() throws {
        let prefs = AppPreferences()
        let original = prefs.saveLocation
        defer { prefs.saveLocation = original }

        let scratch = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mika-qa2-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }

        prefs.saveLocation = scratch
        prefs.autoSaveEnabled = true

        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.green.drawSwatch(in: NSRect(x: 0, y: 0, width: 4, height: 4))
        image.unlockFocus()

        let manager = ScreenshotHistoryManager(preferences: prefs)
        let saved = try XCTUnwrap(manager.autoSave(image))
        let item = try XCTUnwrap(manager.items.first)

        // The user deletes the file in the Finder. The folder itself stays reachable.
        try FileManager.default.removeItem(at: saved)

        manager.deleteItem(item)

        XCTAssertEqual(manager.items.count, 0,
                       "an entry whose file is already gone must still be removable from the list")
    }
}
