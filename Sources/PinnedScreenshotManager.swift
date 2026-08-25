// PinnedScreenshotManager.swift
// MikaScreenSnap
//
// Persistence and lifecycle management for pinned screenshot panels.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
enum PinnedScreenshotManager {
    private static let maxPins = 20
    private static var persistenceDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("MikaScreenSnap/PinnedScreenshots", isDirectory: true)
    }

    // MARK: - Pin Image

    static func pinImage(_ image: NSImage, appState: AppState) -> PinnedScreenshotPanel? {
        guard appState.pinnedPanels.count < maxPins else {
            CaptureLog.report("Maximum pinned screenshots reached (\(maxPins))",
                              message: "Already \(maxPins) pinned screenshots")
            return nil
        }

        let panel = PinnedScreenshotPanel(image: image, appState: appState)
        panel.persistedURL = savePinnedImage(image)
        panel.makeKeyAndOrderFront(nil)
        appState.pinnedPanels.append(panel)

        return panel
    }

    // MARK: - Unpin

    /// Closes a pin **and deletes the image it was persisted to.**
    ///
    /// Closing used to only hide the window, so screen contents piled up unseen in
    /// Application Support and closed pins reappeared on the next launch.
    static func unpinPanel(_ panel: PinnedScreenshotPanel, appState: AppState) {
        panel.orderOut(nil)
        deletePersistedImage(of: panel)
        appState.pinnedPanels.removeAll { $0 === panel }
    }

    static func unpinAll(appState: AppState) {
        for panel in appState.pinnedPanels {
            panel.orderOut(nil)
            deletePersistedImage(of: panel)
        }
        appState.pinnedPanels.removeAll()
    }

    private static func deletePersistedImage(of panel: PinnedScreenshotPanel) {
        guard let url = panel.persistedURL else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
            // Already gone — nothing to report.
        } catch {
            CaptureLog.report(error, action: "Removing pinned screenshot")
        }
        panel.persistedURL = nil
    }

    // MARK: - Storage

    /// Bytes held by persisted pins, so Preferences can account for them.
    static func storageUsage() -> Int64 {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: persistenceDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        ) else { return 0 }

        return files.reduce(into: Int64(0)) { total, url in
            if let attrs = try? fm.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
    }

    /// Closes every pin and empties the persistence directory.
    static func clearAll(appState: AppState) {
        unpinAll(appState: appState)
        try? FileManager.default.removeItem(at: persistenceDir)
    }

    // MARK: - Persistence

    static func restorePins(appState: AppState) {
        let fm = FileManager.default
        let dir = persistenceDir

        guard let files = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }

        // Newest first: sorting filenames ascending restored the *oldest* twenty, so a
        // recent pin could be dropped while an old one came back.
        let imageFiles = files
            .filter { $0.pathExtension.lowercased() == "png" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

        for file in imageFiles.prefix(maxPins) {
            guard let image = NSImage(contentsOf: file) else { continue }
            let panel = PinnedScreenshotPanel(image: image, appState: appState)
            panel.persistedURL = file
            panel.makeKeyAndOrderFront(nil)
            appState.pinnedPanels.append(panel)
        }

        // Anything beyond the limit can never be restored, so it would linger forever.
        for file in imageFiles.dropFirst(maxPins) {
            try? fm.removeItem(at: file)
        }
    }

    @discardableResult
    private static func savePinnedImage(_ image: NSImage) -> URL? {
        let fm = FileManager.default
        let dir = persistenceDir
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let filename = "pin_\(formatter.string(from: Date())).png"
        let fileURL = dir.appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            CaptureLog.report("Could not encode pinned screenshot", message: "Could not pin screenshot")
            return nil
        }

        do {
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            CaptureLog.report(error, action: "Pinning screenshot")
            return nil
        }
    }
}
