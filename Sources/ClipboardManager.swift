import AppKit
import UniformTypeIdentifiers

@MainActor
enum ClipboardManager {
    static func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    /// Puts text on the pasteboard, marked so clipboard managers and history tools leave
    /// it alone.
    ///
    /// Recognised text can be a password that happened to sit inside the selected region.
    static func copyToClipboard(text: String, concealed: Bool) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        if concealed {
            // Convention honoured by clipboard managers (nspasteboard.org).
            pasteboard.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        }
    }

    @discardableResult
    static func saveToFile(_ image: NSImage, url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            CaptureLog.report("Could not encode image as PNG", message: "Could not save screenshot")
            return false
        }

        do {
            try pngData.write(to: url)
            return true
        } catch {
            CaptureLog.report(error, action: "Saving screenshot")
            return false
        }
    }
}
