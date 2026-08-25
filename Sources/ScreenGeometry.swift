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

    /// The display this screen belongs to, for matching against ScreenCaptureKit.
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    /// The screen the pointer is currently on.
    ///
    /// Deliberately not `NSScreen.main`, which follows the key window: with no window of
    /// ours focused it does not point at the display the user is looking at.
    static var underPointer: NSScreen? {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(location) } ?? NSScreen.screens.first
    }

    /// The screen holding the greater part of an AppKit rect.
    static func containing(_ rect: NSRect) -> NSScreen? {
        let best = NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(rect).area < rhs.frame.intersection(rect).area
        }
        guard let best, best.frame.intersects(rect) else { return NSScreen.screens.first }
        return best
    }

    /// An AppKit rect expressed relative to this screen, top-left origin — the shape
    /// `SCStreamConfiguration.sourceRect` expects.
    func sourceRect(forAppKitRect rect: NSRect) -> CGRect {
        ScreenGeometry.sourceRect(forAppKitRect: rect, inScreenFrame: frame)
    }
}

/// The coordinate maths, kept free of `NSScreen` so it can be tested without a display.
enum ScreenGeometry {
    /// Converts a global AppKit rect (bottom-left origin) into one relative to a screen,
    /// with a top-left origin.
    ///
    /// Area captures used to compute this against whichever display ScreenCaptureKit
    /// listed first, which produced the wrong crop on every screen but that one.
    static func sourceRect(forAppKitRect rect: CGRect, inScreenFrame screenFrame: CGRect) -> CGRect {
        CGRect(
            x: rect.origin.x - screenFrame.origin.x,
            y: (screenFrame.origin.y + screenFrame.height) - (rect.origin.y + rect.height),
            width: rect.width,
            height: rect.height
        )
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : width * height }
}
