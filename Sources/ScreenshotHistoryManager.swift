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
    private(set) var items: [HistoryItem] = []
    private let preferences: AppPreferences

    init(preferences: AppPreferences) {
        self.preferences = preferences
        loadHistory()
    }

    // MARK: - Auto-Save

    func autoSave(_ image: NSImage) {
        guard preferences.autoSaveEnabled else { return }

        guard let savedURL = preferences.saveImage(image) else { return }

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
    }

    // MARK: - Load History

    func loadHistory() {
        let saveDir = preferences.saveLocation
        let fm = FileManager.default

        guard let files = try? fm.contentsOfDirectory(
            at: saveDir,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return }

        let imageFiles = files.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "png" || ext == "jpg" || ext == "jpeg"
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
        let fm = FileManager.default
        try? fm.removeItem(at: item.url)
        try? fm.removeItem(at: item.thumbnailURL)
        items.removeAll { $0.id == item.id }
    }

    // MARK: - Clear All

    func clearAll() {
        let fm = FileManager.default
        for item in items {
            try? fm.removeItem(at: item.url)
            try? fm.removeItem(at: item.thumbnailURL)
        }
        let thumbnailDir = preferences.saveLocation.appendingPathComponent(".thumbnails", isDirectory: true)
        try? fm.removeItem(at: thumbnailDir)
        items.removeAll()
    }

    func storageUsage() -> Int64 {
        let fm = FileManager.default
        var total: Int64 = 0
        for item in items {
            if let attrs = try? fm.attributesOfItem(atPath: item.url.path),
               let size = attrs[.size] as? Int64 {
                total += size
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
        let thumbnailDir = preferences.saveLocation.appendingPathComponent(".thumbnails", isDirectory: true)
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
