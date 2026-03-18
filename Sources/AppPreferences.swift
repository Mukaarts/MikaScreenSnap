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

    var imageFormat: ImageFormat {
        didSet { defaults.set(imageFormat.rawValue, forKey: "imageFormat") }
    }

    var jpegQuality: CGFloat {
        didSet { defaults.set(jpegQuality, forKey: "jpegQuality") }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var permissionSkipped: Bool {
        didSet { defaults.set(permissionSkipped, forKey: "permissionSkipped") }
    }

    init() {
        let defaultLocation = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MikaScreenSnap", isDirectory: true)

        self.autoSaveEnabled = defaults.object(forKey: "autoSaveEnabled") as? Bool ?? true
        self.jpegQuality = defaults.object(forKey: "jpegQuality") as? CGFloat ?? 0.85
        self.imageFormat = ImageFormat(rawValue: defaults.string(forKey: "imageFormat") ?? "") ?? .png
        self.hasCompletedOnboarding = defaults.object(forKey: "hasCompletedOnboarding") as? Bool ?? false
        self.permissionSkipped = defaults.object(forKey: "permissionSkipped") as? Bool ?? false

        if let savedPath = defaults.string(forKey: "saveLocation") {
            self.saveLocation = URL(fileURLWithPath: savedPath)
        } else {
            self.saveLocation = defaultLocation
        }

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: saveLocation, withIntermediateDirectories: true)
    }

    func saveImage(_ image: NSImage) -> URL? {
        try? FileManager.default.createDirectory(at: saveLocation, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let ext = imageFormat == .png ? "png" : "jpg"
        let filename = "MikaSnap_\(timestamp).\(ext)"
        let fileURL = saveLocation.appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }

        let data: Data?
        switch imageFormat {
        case .png:
            data = bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: jpegQuality])
        }

        guard let imageData = data else { return nil }

        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to auto-save image: \(error)")
            return nil
        }
    }
}
