// MikaPlusColors.swift
// MikaScreenSnap
//
// Brand color palette for the Mika+ ecosystem.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import SwiftUI

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    enum MikaPlus {
        static let tealPrimary    = NSColor(hex: "#1D9E75")
        static let tealLight      = NSColor(hex: "#5DCAA5")
        static let tealLightest   = NSColor(hex: "#9FE1CB")
        static let tealSurface    = NSColor(hex: "#E1F5EE")
        static let darkBg         = NSColor(hex: "#1A1A2E")
        static let darkBgDeep     = NSColor(hex: "#0F0F1A")
        static let textPrimary    = NSColor(hex: "#E1F5EE")
        static let textSecondary  = NSColor(hex: "#9FE1CB")
        static let destructive    = NSColor(hex: "#E24B4A")
    }
}

extension Color {
    enum MikaPlus {
        static let tealPrimary   = Color(nsColor: NSColor.MikaPlus.tealPrimary)
        static let tealLight     = Color(nsColor: NSColor.MikaPlus.tealLight)
        static let tealLightest  = Color(nsColor: NSColor.MikaPlus.tealLightest)
        static let tealSurface   = Color(nsColor: NSColor.MikaPlus.tealSurface)
        static let darkBg        = Color(nsColor: NSColor.MikaPlus.darkBg)
        static let darkBgDeep    = Color(nsColor: NSColor.MikaPlus.darkBgDeep)
        static let textPrimary   = Color(nsColor: NSColor.MikaPlus.textPrimary)
        static let textSecondary = Color(nsColor: NSColor.MikaPlus.textSecondary)
        static let destructive   = Color(nsColor: NSColor.MikaPlus.destructive)
    }
}
