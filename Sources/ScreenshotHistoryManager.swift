// ScreenshotHistoryManager.swift
// MikaScreenSnap
//
// Manages screenshot history: auto-save, thumbnail generation, browsing.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

struct HistoryItem: Identifiable, Sendable {
    let id: UUID
    let url: URL
    let thumbnailURL: URL
    let date: Date
    let pixelWidth: Int
    let pixelHeight: Int
}

@Observable
@MainActor
final class ScreenshotHistoryManager {
    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg"]

    private(set) var items: [HistoryItem] = []
    private let preferences: AppPreferences

    init(preferences: AppPreferences) {
        self.preferences = preferences
        loadHistory()
    }

    // MARK: - Auto-Save

    /// Saves a fresh capture and returns the file it wrote.
    ///
    /// The caller keeps the URL so the editor can replace the file with the edited image —
    /// auto-save runs before the editor opens, so what lands here is the untouched original.
    @discardableResult
    func autoSave(_ image: NSImage) -> URL? {
        guard preferences.autoSaveEnabled else { return nil }

        guard let savedURL = preferences.saveImage(image) else { return nil }

        // Generate thumbnail
        let thumbnailURL = generateThumbnail(for: image, originalURL: savedURL)

        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let item = HistoryItem(
            id: UUID(),
            url: savedURL,
            thumbnailURL: thumbnailURL ?? savedURL,
            date: Date(),
            pixelWidth: cgImage?.width ?? Int(image.size.width),
            pixelHeight: cgImage?.height ?? Int(image.size.height)
        )
        items.insert(item, at: 0)
        return savedURL
    }

    /// Replaces an already-saved capture with its edited version and refreshes its entry.
    func replaceSaved(at url: URL, with image: NSImage) {
        guard preferences.overwrite(url, with: image) else { return }

        let thumbnailURL = generateThumbnail(for: image, originalURL: url)
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)

        guard let index = items.firstIndex(where: { $0.url == url }) else { return }
        items[index] = HistoryItem(
            id: items[index].id,
            url: url,
            thumbnailURL: thumbnailURL ?? url,
            date: Date(),
            pixelWidth: cgImage?.width ?? Int(image.size.width),
            pixelHeight: cgImage?.height ?? Int(image.size.height)
        )
    }

    // MARK: - Load History

    func loadHistory() {
        // Everything below runs inside the bracket, not after it. `resolve` alone hands
        // back a URL and closes the access again in the same call — reading the folder
        // afterwards fails under the sandbox, and the history stays empty with no error.
        SaveLocationStore.readingSaveFolder(preferences) { saveDir in
            loadHistory(from: saveDir)
        }
    }

    private func loadHistory(from saveDir: URL) {
        let fm = FileManager.default

        guard let files = try? fm.contentsOfDirectory(
            at: saveDir,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return }

        let imageFiles = files.filter { url in
            let ext = url.pathExtension.lowercased()
            return ScreenshotHistoryManager.imageExtensions.contains(ext)
        }

        let thumbnailDir = saveDir.appendingPathComponent(".thumbnails", isDirectory: true)

        items = imageFiles.compactMap { url -> HistoryItem? in
            guard let attrs = try? fm.attributesOfItem(atPath: url.path),
                  let date = attrs[.modificationDate] as? Date else { return nil }

            let thumbURL = thumbnailDir.appendingPathComponent(url.lastPathComponent)
            let size = imageSize(at: url)

            return HistoryItem(
                id: UUID(),
                url: url,
                thumbnailURL: fm.fileExists(atPath: thumbURL.path) ? thumbURL : url,
                date: date,
                pixelWidth: size.width,
                pixelHeight: size.height
            )
        }.sorted { $0.date > $1.date }
    }

    // MARK: - Delete

    func deleteItem(_ item: HistoryItem) {
        let removed = SaveLocationStore.withSaveFolder(preferences, action: "Deleting screenshot") { _ -> Bool in
            let fm = FileManager.default
            do {
                try fm.removeItem(at: item.url)
            } catch let error as NSError
                where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
                // Deleting has three outcomes, and only two are failures: the folder is
                // unreachable, the file could not be removed — or the file was already
                // gone, which is what the user wanted. Treating the third as an error left
                // entries that could never be cleared from the history.
            }
            // The capture is what the user asked to delete; a missing thumbnail is not a
            // failure worth reporting.
            try? fm.removeItem(at: item.thumbnailURL)
            return true
        }

        // A delete that fails must not leave the entry gone from the list while the file
        // is still on disk — that is how a user comes to believe a screenshot is deleted
        // when it is not.
        guard removed == true else { return }
        items.removeAll { $0.id == item.id }
    }

    // MARK: - Clear All

    /// Deletes every capture in the save location, not just the ones currently listed.
    ///
    /// Files that were not picked up at launch used to survive "Clear History" while the
    /// user was told everything had been deleted.
    func clearAll() {
        let cleared = SaveLocationStore.withSaveFolder(preferences, action: "Clearing history") { saveDir -> Bool in
            let fm = FileManager.default

            if let files = try? fm.contentsOfDirectory(
                at: saveDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            ) {
                for url in files where ScreenshotHistoryManager.imageExtensions.contains(url.pathExtension.lowercased()) {
                    try? fm.removeItem(at: url)
                }
            }

            let thumbnailDir = saveDir.appendingPathComponent(".thumbnails", isDirectory: true)
            try? fm.removeItem(at: thumbnailDir)
            return true
        }

        guard cleared == true else { return }
        items.removeAll()
    }

    /// Bytes used by captures **and** their thumbnails.
    ///
    /// Thumbnails used to be left out, so the figure shown in Preferences was always too
    /// small.
    func storageUsage() -> Int64 {
        SaveLocationStore.readingSaveFolder(preferences) { _ in
            measureStorage()
        } ?? 0
    }

    private func measureStorage() -> Int64 {
        let fm = FileManager.default
        var total: Int64 = 0
        for item in items {
            for url in [item.url, item.thumbnailURL] where fm.fileExists(atPath: url.path) {
                if let attrs = try? fm.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int64 {
                    total += size
                }
            }
        }
        return total
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(for image: NSImage, originalURL: URL) -> URL? {
        // Same bracket as everywhere else: the thumbnail lands next to the capture, in
        // the folder the sandbox only opens on request.
        // A thumbnail is a by-product, not something the user asked for — its failure is
        // not worth a notice, and the capture itself already reported if it went wrong.
        return SaveLocationStore.readingSaveFolder(preferences) { saveDir -> URL? in
            writeThumbnail(for: image, originalURL: originalURL, in: saveDir)
        } ?? nil
    }

    private func writeThumbnail(for image: NSImage, originalURL: URL, in saveDir: URL) -> URL? {
        let thumbnailDir = saveDir.appendingPathComponent(".thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: thumbnailDir, withIntermediateDirectories: true)

        let thumbURL = thumbnailDir.appendingPathComponent(originalURL.lastPathComponent)
        let maxDim: CGFloat = 200

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let origW = CGFloat(cgImage.width)
        let origH = CGFloat(cgImage.height)
        let scale = min(maxDim / origW, maxDim / origH, 1.0)
        let thumbW = Int(origW * scale)
        let thumbH = Int(origH * scale)

        guard let ctx = CGContext(
            data: nil, width: thumbW, height: thumbH,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: thumbW, height: thumbH))

        guard let thumbImage = ctx.makeImage() else { return nil }

        let nsThumb = NSImage(cgImage: thumbImage, size: NSSize(width: thumbW, height: thumbH))
        guard let tiffData = nsThumb.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            return nil
        }

        try? jpegData.write(to: thumbURL)
        return thumbURL
    }

    private func imageSize(at url: URL) -> (width: Int, height: Int) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int else {
            return (0, 0)
        }
        return (w, h)
    }
}
