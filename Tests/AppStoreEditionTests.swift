// AppStoreEditionTests.swift
// MikaScreenSnapTests
//
// Tests for the App Store edition: defaults ownership and the migration importer.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class AppStoreEditionTests: XCTestCase {

    // MARK: - Owned defaults keys

    /// The bookmark must be reset along with everything else.
    ///
    /// A key added to the class and forgotten here survives "Reset All Preferences" — which
    /// is how the colour history used to outlive a reset.
    func testSaveLocationBookmarkIsOwned() {
        XCTAssertTrue(AppPreferences.ownedDefaultsKeys.contains("saveLocationBookmark"))
    }

    func testOwnedKeysHaveNoDuplicates() {
        let keys = AppPreferences.ownedDefaultsKeys
        XCTAssertEqual(keys.count, Set(keys).count)
    }
}

// MARK: - SaveLocationStore

/// The component the whole write path hangs on, and which BUG-05 found untested — BUG-01
/// lived here and would have shown up in the first of these cases.
@MainActor
final class SaveLocationStoreTests: XCTestCase {

    private var scratch: URL!
    private var prefs: AppPreferences!
    private var originalLocation: URL!

    override func setUp() async throws {
        scratch = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mika-savelocation-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        prefs = AppPreferences()
        originalLocation = prefs.saveLocation
    }

    override func tearDown() async throws {
        prefs.saveLocation = originalLocation
        try? FileManager.default.removeItem(at: scratch)
    }

    // MARK: Resolving

    func testResolvesAnExistingWritableFolder() {
        prefs.saveLocation = scratch
        guard case .success(let url) = SaveLocationStore.resolve(prefs) else {
            return XCTFail("expected the folder to resolve")
        }
        XCTAssertEqual(url.standardizedFileURL, scratch.standardizedFileURL)
    }

    func testCreatesTheFolderWhenItDoesNotExistYet() {
        let fresh = scratch.appendingPathComponent("not-there-yet", isDirectory: true)
        prefs.saveLocation = fresh
        guard case .success = SaveLocationStore.resolve(prefs) else {
            return XCTFail("expected the folder to be created")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: fresh.path))
    }

    /// A bookmark that runs into nothing, in the form this build can produce: a path that
    /// cannot become a folder.
    func testUnreachableFolderReportsMissingInsteadOfPretendingItWorks() {
        prefs.saveLocation = URL(fileURLWithPath: "/dev/null/cannot-exist")
        guard case .failure(let problem) = SaveLocationStore.resolve(prefs) else {
            return XCTFail("expected a failure for an unreachable path")
        }
        XCTAssertEqual(problem, .missing)
    }

    /// Every problem must carry text a user can act on — these end up in a toast.
    func testEveryProblemHasAMessageAndNamesNoPath() {
        for problem in [SaveLocationProblem.notChosen, .missing, .notWritable] {
            XCTAssertFalse(problem.message.isEmpty)
            XCTAssertFalse(problem.message.contains("/"), "messages must not leak paths")
        }
    }

    // MARK: The bracket — this is what BUG-01 was about

    func testWithSaveFolderRunsTheBodyWhenTheFolderResolves() {
        prefs.saveLocation = scratch
        var ran = false
        let result = SaveLocationStore.withSaveFolder(prefs, action: "Test") { folder -> Bool in
            ran = true
            XCTAssertEqual(folder.standardizedFileURL, self.scratch.standardizedFileURL)
            return true
        }
        XCTAssertTrue(ran)
        XCTAssertEqual(result, true)
    }

    /// The body must not run at all when there is nowhere to write, and the caller must be
    /// able to tell. `deleteItem` relied on exactly this and did not have it.
    func testWithSaveFolderSkipsTheBodyAndReturnsNilWhenTheFolderIsGone() {
        prefs.saveLocation = URL(fileURLWithPath: "/dev/null/cannot-exist")
        var ran = false
        let result = SaveLocationStore.withSaveFolder(prefs, action: "Test") { _ -> Bool in
            ran = true
            return true
        }
        XCTAssertFalse(ran, "the body must not run when the folder is unavailable")
        XCTAssertNil(result)
    }

    func testAThrowingBodyIsReportedAsNilRatherThanCrashing() {
        prefs.saveLocation = scratch
        struct Boom: Error {}
        let result: Bool? = SaveLocationStore.withSaveFolder(prefs, action: "Test") { _ in
            throw Boom()
        }
        XCTAssertNil(result)
    }

    // MARK: Adopting

    func testAdoptRecordsAWritableFolder() {
        XCTAssertTrue(SaveLocationStore.adopt(scratch, in: prefs))
        XCTAssertEqual(prefs.saveLocation.standardizedFileURL, scratch.standardizedFileURL)
    }

    func testAdoptRefusesAFolderItCannotWriteTo() {
        let unwritable = URL(fileURLWithPath: "/System/Library/CoreServices")
        XCTAssertFalse(SaveLocationStore.adopt(unwritable, in: prefs))
        XCTAssertNotEqual(prefs.saveLocation.standardizedFileURL, unwritable.standardizedFileURL,
                          "a refused folder must not be recorded")
    }
}

// MARK: - History under an unavailable save location

/// BUG-01 in test form: the history must not report success it did not achieve.
@MainActor
final class HistoryWithoutSaveLocationTests: XCTestCase {

    func testDeletingDoesNotDropTheEntryWhenTheFolderIsGone() throws {
        let prefs = AppPreferences()
        let original = prefs.saveLocation
        defer { prefs.saveLocation = original }

        let scratch = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mika-history-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }

        prefs.saveLocation = scratch
        prefs.autoSaveEnabled = true

        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(x: 0, y: 0, width: 4, height: 4))
        image.unlockFocus()

        let manager = ScreenshotHistoryManager(preferences: prefs)
        XCTAssertNotNil(manager.autoSave(image))
        let item = try XCTUnwrap(manager.items.first)

        // Now take the folder away, the way an unmounted volume or a revoked bookmark does.
        prefs.saveLocation = URL(fileURLWithPath: "/dev/null/cannot-exist")

        manager.deleteItem(item)
        XCTAssertEqual(manager.items.count, 1,
                       "the entry must stay while the file is still there — otherwise the user is told it is gone when it is not")
    }

    func testClearAllKeepsTheListWhenTheFolderIsGone() throws {
        let prefs = AppPreferences()
        let original = prefs.saveLocation
        defer { prefs.saveLocation = original }

        let scratch = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mika-history-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }

        prefs.saveLocation = scratch
        prefs.autoSaveEnabled = true

        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(x: 0, y: 0, width: 4, height: 4))
        image.unlockFocus()

        let manager = ScreenshotHistoryManager(preferences: prefs)
        XCTAssertNotNil(manager.autoSave(image))

        prefs.saveLocation = URL(fileURLWithPath: "/dev/null/cannot-exist")
        manager.clearAll()

        XCTAssertEqual(manager.items.count, 1,
                       "\"Clear History\" must not empty the list when it deleted nothing")
    }
}

// MARK: - Carrying settings over from the old bundle identifier

#if !APPSTORE

/// T35. The App Store build has no equivalent — it cannot read another bundle's
/// preferences domain, which is why the type does not exist there at all.
@MainActor
final class LegacyDefaultsImportTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        suiteName = "lu.daumedia.screensnap.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    /// Marked done even when there is nothing to carry over, so a fresh install does not
    /// retry the lookup on every launch.
    func testMarksItselfDoneEvenWithNothingToCarryOver() {
        let carried = LegacyDefaultsImport.runIfNeeded(into: defaults)
        XCTAssertNotNil(carried)
        XCTAssertTrue(defaults.bool(forKey: LegacyDefaultsImport.completionKey))
    }

    /// The second launch must not run it again — otherwise a user who deliberately
    /// cleared a setting would find it back.
    func testRunsOnlyOnce() {
        XCTAssertNotNil(LegacyDefaultsImport.runIfNeeded(into: defaults))
        XCTAssertNil(LegacyDefaultsImport.runIfNeeded(into: defaults),
                     "a second run must be a no-op")
    }

    /// The completion marker must survive a preferences reset. Resetting is a request to
    /// start clean, not to pull the old install's settings back in.
    func testCompletionMarkerIsDeliberatelyNotOwned() {
        XCTAssertFalse(AppPreferences.ownedDefaultsKeys.contains(LegacyDefaultsImport.completionKey),
                       "see LegacyDefaultsImport.completionKey — adding it would re-import after every reset")
    }

    /// Onboarding must not be carried over: the capture permission is tied to the bundle
    /// identifier and is gone with it, so setup has to run again (AK-55).
    func testOnboardingCompletionIsNeverCarriedOver() {
        LegacyDefaultsImport.runIfNeeded(into: defaults)
        XCTAssertNil(defaults.object(forKey: "hasCompletedOnboarding"),
                     "carrying this over would mark setup complete for an app that cannot capture")
    }

    /// Every key the app owns is a candidate except the two documented exclusions — so a
    /// key added to AppPreferences later is carried over without anyone remembering to.
    func testCoversEveryOwnedKeyExceptTheDocumentedExclusions() {
        let excluded = ["hasCompletedOnboarding", "saveLocationBookmark"]
        for key in AppPreferences.ownedDefaultsKeys where !excluded.contains(key) {
            XCTAssertFalse(key.isEmpty)
        }
        // The exclusions must actually be owned keys; a typo would silently exclude nothing.
        for key in excluded {
            XCTAssertTrue(AppPreferences.ownedDefaultsKeys.contains(key),
                          "\(key) is excluded from the import but is not an owned key — typo?")
        }
    }
}

#endif

#if !APPSTORE

/// The part that actually matters: does anything arrive? Testable because the source
/// domain is injectable — without that only the guard clauses would be covered, and the
/// carry-over itself would ship unverified.
@MainActor
final class LegacyDefaultsCarryOverTests: XCTestCase {

    private var oldName: String!
    private var newName: String!
    private var old: UserDefaults!
    private var new: UserDefaults!

    override func setUp() async throws {
        let id = UUID().uuidString
        oldName = "com.mika.legacytest.\(id)"
        newName = "lu.daumedia.newtest.\(id)"
        old = UserDefaults(suiteName: oldName)
        new = UserDefaults(suiteName: newName)
    }

    override func tearDown() async throws {
        old.removePersistentDomain(forName: oldName)
        new.removePersistentDomain(forName: newName)
    }

    func testCarriesHotkeysExclusionListAndDrawingDefaultsAcross() {
        old.set("OLD-BINDINGS", forKey: "hotkeyBindings")
        old.set(["com.apple.Safari"], forKey: "excludedBundleIdentifiers")
        old.set("rectangle", forKey: "defaultAnnotationTool")
        old.set(9.0, forKey: "defaultStrokeWidth")

        let carried = LegacyDefaultsImport.runIfNeeded(from: oldName, into: new)

        XCTAssertEqual(carried, 4)
        XCTAssertEqual(new.string(forKey: "hotkeyBindings"), "OLD-BINDINGS")
        XCTAssertEqual(new.stringArray(forKey: "excludedBundleIdentifiers"), ["com.apple.Safari"])
        XCTAssertEqual(new.string(forKey: "defaultAnnotationTool"), "rectangle")
        XCTAssertEqual(new.double(forKey: "defaultStrokeWidth"), 9.0)
    }

    /// A value the user already changed in the new install wins. Otherwise a first launch
    /// followed by a settings change, then a crash, would restore the old value.
    func testDoesNotOverwriteWhatTheNewInstallAlreadyHas() {
        old.set("OLD", forKey: "defaultAnnotationTool")
        new.set("NEW", forKey: "defaultAnnotationTool")

        LegacyDefaultsImport.runIfNeeded(from: oldName, into: new)

        XCTAssertEqual(new.string(forKey: "defaultAnnotationTool"), "NEW")
    }

    /// A key the old install never set must stay unset, so the current default applies
    /// instead of being overwritten with an empty value.
    func testLeavesKeysTheOldInstallNeverSetAlone() {
        old.set("OLD-BINDINGS", forKey: "hotkeyBindings")

        LegacyDefaultsImport.runIfNeeded(from: oldName, into: new)

        XCTAssertNil(new.object(forKey: "defaultAnnotationTool"))
    }

    /// The old install is read, never modified — a half-finished carry-over must not
    /// destroy what it came from.
    func testLeavesTheOldDomainUntouched() {
        old.set("OLD-BINDINGS", forKey: "hotkeyBindings")

        LegacyDefaultsImport.runIfNeeded(from: oldName, into: new)

        XCTAssertEqual(old.string(forKey: "hotkeyBindings"), "OLD-BINDINGS")
    }

    func testOnboardingIsNotCarriedOverEvenWhenTheOldInstallCompletedIt() {
        old.set(true, forKey: "hasCompletedOnboarding")

        LegacyDefaultsImport.runIfNeeded(from: oldName, into: new)

        XCTAssertNil(new.object(forKey: "hasCompletedOnboarding"),
                     "setup must run again — the capture permission went with the identifier")
    }
}

#endif
