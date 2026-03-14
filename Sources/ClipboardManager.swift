import AppKit
import UniformTypeIdentifiers

enum ClipboardManager {
    static func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    @discardableResult
    static func saveToDesktop(_ image: NSImage) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "MikaSnap_\(timestamp).png"

        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent(filename)

        if saveToFile(image, url: fileURL) {
            return fileURL
        }
        return nil
    }

    @discardableResult
    static func saveToFile(_ image: NSImage, url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("Failed to create PNG data")
            return false
        }

        do {
            try pngData.write(to: url)
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
}
