// ColorPickerEngine.swift
// MikaScreenSnap
//
// Pixel color sampling and format conversion for the screen color picker.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

struct PickedColor: Sendable {
    let nsColor: NSColor
    let hex: String
    let rgb: (r: Int, g: Int, b: Int)
    let hsl: (h: Int, s: Int, l: Int)

    init(nsColor: NSColor) {
        let rgb = nsColor.usingColorSpace(.sRGB) ?? nsColor
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))

        self.nsColor = nsColor
        self.hex = String(format: "#%02X%02X%02X", r, g, b)
        self.rgb = (r, g, b)

        // RGB to HSL
        let rf = rgb.redComponent
        let gf = rgb.greenComponent
        let bf = rgb.blueComponent
        let maxC = max(rf, gf, bf)
        let minC = min(rf, gf, bf)
        let delta = maxC - minC
        let l = (maxC + minC) / 2

        var h: CGFloat = 0
        var s: CGFloat = 0

        if delta > 0 {
            s = l > 0.5 ? delta / (2 - maxC - minC) : delta / (maxC + minC)

            if maxC == rf {
                h = ((gf - bf) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == gf {
                h = (bf - rf) / delta + 2
            } else {
                h = (rf - gf) / delta + 4
            }
            h *= 60
            if h < 0 { h += 360 }
        }

        self.hsl = (Int(round(h)), Int(round(s * 100)), Int(round(l * 100)))
    }
}

@MainActor
enum ColorPickerEngine {
    /// Sample the pixel color at the given screen-space point.
    /// Uses CGWindowListCreateImage to capture a 1x1 pixel at the cursor location,
    /// excluding the specified window IDs (e.g., the loupe panel).
    static func sampleColor(at screenPoint: CGPoint, excluding windowIDs: [CGWindowID] = []) -> PickedColor? {
        // Capture a 1x1 area at the cursor position
        let captureRect = CGRect(x: screenPoint.x, y: screenPoint.y, width: 1, height: 1)

        guard let cgImage = CGWindowListCreateImage(
            captureRect,
            .optionOnScreenBelowWindow,
            windowIDs.first ?? kCGNullWindowID,
            [.bestResolution]
        ) else { return nil }

        // Extract pixel color
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 3 else { return nil }

        let r = CGFloat(ptr[0]) / 255.0
        let g = CGFloat(ptr[1]) / 255.0
        let b = CGFloat(ptr[2]) / 255.0

        let color = NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
        return PickedColor(nsColor: color)
    }

    /// Capture a magnified region around the given screen point for the loupe display.
    static func captureLoupeRegion(at screenPoint: CGPoint, radius: Int, excluding windowIDs: [CGWindowID] = []) -> CGImage? {
        let size = radius * 2
        let captureRect = CGRect(
            x: screenPoint.x - CGFloat(radius),
            y: screenPoint.y - CGFloat(radius),
            width: CGFloat(size),
            height: CGFloat(size)
        )

        return CGWindowListCreateImage(
            captureRect,
            .optionOnScreenBelowWindow,
            windowIDs.first ?? kCGNullWindowID,
            [.bestResolution]
        )
    }
}
