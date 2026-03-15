// ColorHistoryManager.swift
// MikaScreenSnap
//
// Persists recent picked colors and a user palette via UserDefaults.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@Observable
@MainActor
final class ColorHistoryManager {
    private let defaults = UserDefaults.standard
    private let historyKey = "colorHistory"
    private let paletteKey = "colorPalette"

    private(set) var recentColors: [String] = []    // HEX strings, max 10
    private(set) var palette: [String] = []          // HEX strings, max 20

    init() {
        self.recentColors = defaults.stringArray(forKey: historyKey) ?? []
        self.palette = defaults.stringArray(forKey: paletteKey) ?? []
    }

    func addColor(_ hex: String) {
        recentColors.removeAll { $0 == hex }
        recentColors.insert(hex, at: 0)
        if recentColors.count > 10 {
            recentColors = Array(recentColors.prefix(10))
        }
        defaults.set(recentColors, forKey: historyKey)
    }

    func addToPalette(_ hex: String) {
        if !palette.contains(hex) {
            palette.insert(hex, at: 0)
            if palette.count > 20 {
                palette = Array(palette.prefix(20))
            }
            defaults.set(palette, forKey: paletteKey)
        }
    }

    func removeFromPalette(_ hex: String) {
        palette.removeAll { $0 == hex }
        defaults.set(palette, forKey: paletteKey)
    }

    /// Convert a HEX string to NSColor.
    static func colorFromHex(_ hex: String) -> NSColor {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }

        guard hexString.count == 6,
              let hexValue = UInt64(hexString, radix: 16) else {
            return .gray
        }

        let r = CGFloat((hexValue >> 16) & 0xFF) / 255.0
        let g = CGFloat((hexValue >> 8) & 0xFF) / 255.0
        let b = CGFloat(hexValue & 0xFF) / 255.0

        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
}
