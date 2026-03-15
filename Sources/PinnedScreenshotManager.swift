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
            print("Maximum pinned screenshots reached (\(maxPins))")
            return nil
        }

        let panel = PinnedScreenshotPanel(image: image, appState: appState)
        panel.makeKeyAndOrderFront(nil)
        appState.pinnedPanels.append(panel)

        // Persist
        savePinnedImage(image)

        return panel
    }

    // MARK: - Unpin

    static func unpinPanel(_ panel: PinnedScreenshotPanel, appState: AppState) {
        panel.orderOut(nil)
        appState.pinnedPanels.removeAll { $0 === panel }
    }

    static func unpinAll(appState: AppState) {
        for panel in appState.pinnedPanels {
            panel.orderOut(nil)
        }
        appState.pinnedPanels.removeAll()
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

        let imageFiles = files.filter { $0.pathExtension.lowercased() == "png" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        for file in imageFiles.prefix(maxPins) {
            if let image = NSImage(contentsOf: file) {
                let panel = PinnedScreenshotPanel(image: image, appState: appState)
                panel.makeKeyAndOrderFront(nil)
                appState.pinnedPanels.append(panel)
            }
        }
    }

    private static func savePinnedImage(_ image: NSImage) {
        let fm = FileManager.default
        let dir = persistenceDir
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        let filename = "pin_\(formatter.string(from: Date())).png"
        let fileURL = dir.appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else { return }

        try? pngData.write(to: fileURL)
    }
}
