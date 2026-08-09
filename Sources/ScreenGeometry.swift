// ScreenGeometry.swift
// MikaScreenSnap
//
// Conversions between AppKit and CoreGraphics screen coordinates.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
extension NSScreen {
    /// Height of the display that owns the AppKit origin.
    ///
    /// Not `NSScreen.main` — that follows the key window and moves between displays,
    /// which silently breaks the y-flip on a multi-display setup.
    static var primaryHeight: CGFloat {
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens.first
        return primary?.frame.height ?? 0
    }

    /// AppKit global point (bottom-left origin) to global CoreGraphics space (top-left origin).
    static func coreGraphicsPoint(fromAppKit point: NSPoint) -> CGPoint {
        CGPoint(x: point.x, y: primaryHeight - point.y)
    }

    /// Global CoreGraphics rect (top-left origin) to AppKit global coordinates.
    static func appKitRect(fromCoreGraphics rect: CGRect) -> NSRect {
        NSRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}
