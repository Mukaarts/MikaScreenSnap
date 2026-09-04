// AppPreferences.swift
// MikaScreenSnap
//
// User preferences backed by UserDefaults: auto-save, save location, image format.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

enum ImageFormat: String, CaseIterable, Sendable {
    case png = "PNG"
    case jpeg = "JPEG"
}

@Observable
@MainActor
final class AppPreferences {
    private let defaults = UserDefaults.standard

    var autoSaveEnabled: Bool {
        didSet { defaults.set(autoSaveEnabled, forKey: "autoSaveEnabled") }
    }

    var saveLocation: URL {
        didSet { defaults.set(saveLocation.path, forKey: "saveLocation") }
    }

    /// Security-scoped bookmark for the folder the user picked, App Store build only.
    ///
    /// A plain path is worthless under the sandbox: it survives a restart but the
    /// permission to write there does not. The bookmark carries both.
    var saveLocationBookmark: Data? {
        didSet { defaults.set(saveLocationBookmark, forKey: "saveLocationBookmark") }
    }

    var imageFormat: ImageFormat {
        didSet { defaults.set(imageFormat.rawValue, forKey: "imageFormat") }
    }

    var jpegQuality: CGFloat {
        didSet { defaults.set(jpegQuality, forKey: "jpegQuality") }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var captureSoundEnabled: Bool {
        didSet { defaults.set(captureSoundEnabled, forKey: "captureSoundEnabled") }
    }

    var defaultAnnotationTool: String {
        didSet { defaults.set(defaultAnnotationTool, forKey: "defaultAnnotationTool") }
    }

    var defaultStrokeColorData: Data? {
        didSet { defaults.set(defaultStrokeColorData, forKey: "defaultStrokeColorData") }
    }

    var defaultStrokeWidth: CGFloat {
        didSet { defaults.set(defaultStrokeWidth, forKey: "defaultStrokeWidth") }
    }

    var rememberLastTool: Bool {
        didSet { defaults.set(rememberLastTool, forKey: "rememberLastTool") }
    }

    var showToolbarLabels: Bool {
        didSet { defaults.set(showToolbarLabels, forKey: "showToolbarLabels") }
    }

    /// Bundle identifiers whose windows are never included in a capture.
    var excludedBundleIdentifiers: Set<String> {
        didSet { defaults.set(Array(excludedBundleIdentifiers), forKey: "excludedBundleIdentifiers") }
    }

    /// Accessibility overlays that sit on top of everything and would otherwise be
    /// baked into every screenshot.
    static let defaultExcludedBundleIdentifiers = [
        "com.apple.inputmethod.AssistiveControl",   // Accessibility Keyboard + Keyboard Viewer
        "com.apple.DwellControl",                   // Dwell Control (pointer control panel)
        "com.apple.AccessibilityVisualsAgent",      // Zoom / "shake to find pointer" visuals
    ]

    var defaultStrokeNSColor: NSColor {
        get {
            guard let data = defaultStrokeColorData,
                  let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
            else { return .systemRed }
            return color
        }
        set {
            defaultStrokeColorData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
        }
    }

    init() {
        // Runs before the first read below, so the carried-over values are simply there.
        // No-op after the first launch, and absent entirely in the App Store build.
        #if !APPSTORE
        LegacyDefaultsImport.runIfNeeded()
        #endif

        let defaultLocation = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MikaScreenSnap", isDirectory: true)

        self.autoSaveEnabled = defaults.object(forKey: "autoSaveEnabled") as? Bool ?? true
        self.jpegQuality = defaults.object(forKey: "jpegQuality") as? CGFloat ?? 0.85
        self.imageFormat = ImageFormat(rawValue: defaults.string(forKey: "imageFormat") ?? "") ?? .png
        self.hasCompletedOnboarding = defaults.object(forKey: "hasCompletedOnboarding") as? Bool ?? false
        self.captureSoundEnabled = defaults.object(forKey: "captureSoundEnabled") as? Bool ?? true
        self.defaultAnnotationTool = defaults.string(forKey: "defaultAnnotationTool") ?? "arrow"
        self.defaultStrokeColorData = defaults.data(forKey: "defaultStrokeColorData")
        self.defaultStrokeWidth = defaults.object(forKey: "defaultStrokeWidth") as? CGFloat ?? 4.0
        self.rememberLastTool = defaults.object(forKey: "rememberLastTool") as? Bool ?? true
        self.showToolbarLabels = defaults.object(forKey: "showToolbarLabels") as? Bool ?? false
        // An explicitly emptied list stays empty — only a missing key falls back to the defaults.
        self.excludedBundleIdentifiers = Set(
            defaults.stringArray(forKey: "excludedBundleIdentifiers")
                ?? AppPreferences.defaultExcludedBundleIdentifiers
        )

        self.saveLocationBookmark = defaults.data(forKey: "saveLocationBookmark")

        if let savedPath = defaults.string(forKey: "saveLocation") {
            self.saveLocation = URL(fileURLWithPath: savedPath)
        } else {
            self.saveLocation = defaultLocation
        }

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: saveLocation, withIntermediateDirectories: true)
    }

    /// Every defaults key the app owns.
    ///
    /// Kept next to the properties that write them: a key added above and forgotten here
    /// survives "Reset All Preferences", which is how the colour history used to outlive
    /// a reset.
    static let ownedDefaultsKeys = [
        "autoSaveEnabled", "saveLocation", "imageFormat", "jpegQuality",
        "hasCompletedOnboarding",
        "captureSoundEnabled",
        "defaultAnnotationTool", "defaultStrokeColorData", "defaultStrokeWidth",
        "rememberLastTool", "showToolbarLabels", "hotkeyBindings",
        "excludedBundleIdentifiers",
        "saveLocationBookmark",
        ColorHistoryManager.historyDefaultsKey,
        ColorHistoryManager.paletteDefaultsKey,
    ]

    /// Resets everything the app owns.
    ///
    /// - Returns: `true` when the caller must show first-run setup again. Only the App
    ///   Store build ever needs this: the reset clears the save-location bookmark, and
    ///   first-run setup is the only place that asks for a folder. Returning it rather
    ///   than just clearing `hasCompletedOnboarding` matters because that flag is read
    ///   exactly once, at launch — setting it alone left the running app with nowhere to
    ///   write until the next restart.
    @discardableResult
    func resetAllPreferences() -> Bool {
        for key in AppPreferences.ownedDefaultsKeys {
            defaults.removeObject(forKey: key)
        }

        LaunchAtLoginManager().setEnabled(false)

        // Re-initialize from defaults
        let defaultLocation = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MikaScreenSnap", isDirectory: true)

        autoSaveEnabled = true
        jpegQuality = 0.85
        imageFormat = .png
        // The direct build keeps onboarding completed: it writes to ~/Pictures and needs
        // nothing from the user. The App Store build must not — the reset clears the
        // bookmark below, and first-run setup is the only place that asks for a folder.
        #if APPSTORE
        let needsSetupAgain = SaveLocationStore.isSandboxed
        #else
        let needsSetupAgain = false
        #endif
        hasCompletedOnboarding = !needsSetupAgain
        captureSoundEnabled = true
        defaultAnnotationTool = "arrow"
        defaultStrokeColorData = nil
        defaultStrokeWidth = 4.0
        rememberLastTool = true
        showToolbarLabels = false
        excludedBundleIdentifiers = Set(AppPreferences.defaultExcludedBundleIdentifiers)
        saveLocation = defaultLocation
        saveLocationBookmark = nil

        return needsSetupAgain
    }

    /// Encodes an image in the configured format.
    func encode(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }

        switch imageFormat {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: jpegQuality])
        }
    }

    var fileExtension: String { imageFormat == .png ? "png" : "jpg" }

    /// A capture filename that cannot collide with an existing one.
    ///
    /// The timestamp carries milliseconds and a counter is appended if that still lands on
    /// an existing file — two captures inside the same second used to overwrite each other
    /// silently.
    func uniqueCaptureURL(in directory: URL) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let timestamp = formatter.string(from: Date())

        var candidate = directory.appendingPathComponent("MikaSnap_\(timestamp).\(fileExtension)")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("MikaSnap_\(timestamp)_\(counter).\(fileExtension)")
            counter += 1
        }
        return candidate
    }

    /// Writes an image into the configured save location.
    /// - Returns: the file it wrote, or `nil` — the caller is expected to tell the user.
    func saveImage(_ image: NSImage) -> URL? {
        guard let imageData = encode(image) else {
            CaptureLog.report("Could not encode capture as \(imageFormat.rawValue)",
                              message: "Could not save screenshot")
            return nil
        }

        // The save folder is resolved and access opened here, not held for the process
        // lifetime — see SaveLocationStore. A missing folder reports itself instead of
        // failing silently.
        return SaveLocationStore.withSaveFolder(self, action: "Saving screenshot") { folder in
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let fileURL = uniqueCaptureURL(in: folder)
            try imageData.write(to: fileURL)
            return fileURL
        }
    }

    /// Overwrites an already-saved capture with its edited version.
    ///
    /// Auto-save runs before the editor opens, so the file on disk is the untouched
    /// original. Once the user exports — or redacts anything — that original must not
    /// survive.
    func overwrite(_ url: URL, with image: NSImage) -> Bool {
        guard let imageData = encode(image) else {
            CaptureLog.report("Could not encode edited capture", message: "Could not update screenshot")
            return false
        }
        // Goes through the same bracket as saveImage: this is the path that replaces the
        // auto-saved original with the censored version, and it must not fail quietly in
        // the sandbox — that would leave the unredacted file behind.
        return SaveLocationStore.withSaveFolder(self, action: "Updating screenshot") { _ in
            try imageData.write(to: url)
            return true
        } ?? false
    }
}
