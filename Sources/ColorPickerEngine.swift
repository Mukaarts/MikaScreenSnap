// ColorPickerEngine.swift
// MikaScreenSnap
//
// Pixel color sampling and format conversion for the screen color picker.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
@preconcurrency import ScreenCaptureKit

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

/// Samples screen pixels for the colour picker.
///
/// `CGWindowListCreateImage` is deprecated and no longer a viable path, but its
/// ScreenCaptureKit replacement is async — and the loupe redraws on every mouse move,
/// where awaiting a round trip per sample would stutter. So the screen is snapshotted
/// once when the picker starts and every sample reads from that buffer synchronously.
///
/// Consequence: live content (video, animation) under the cursor does not update while
/// the picker is open.
@MainActor
final class ColorPickerEngine {
    private struct DisplaySnapshot {
        /// Display bounds in global CoreGraphics points, top-left origin.
        let frame: CGRect
        let image: CGImage
        let bytesPerPixel: Int
        let bytesPerRow: Int
        let data: CFData
        /// Pixels per point.
        let scale: CGFloat
    }

    private var snapshots: [DisplaySnapshot] = []

    /// Captures every display once, excluding our own overlays and the user's blocked apps.
    func loadSnapshots(excludedWindows: [SCWindow], content: SCShareableContent) async throws {
        var loaded: [DisplaySnapshot] = []

        for display in content.displays {
            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            let scale = CGFloat(filter.pointPixelScale)

            let config = SCStreamConfiguration()
            config.width = Int((CGFloat(display.width) * scale).rounded())
            config.height = Int((CGFloat(display.height) * scale).rounded())
            config.showsCursor = false
            config.shouldBeOpaque = true

            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

            guard let provider = image.dataProvider, let data = provider.data else { continue }

            loaded.append(DisplaySnapshot(
                frame: display.frame,
                image: image,
                bytesPerPixel: image.bitsPerPixel / 8,
                bytesPerRow: image.bytesPerRow,
                data: data,
                scale: scale
            ))
        }

        snapshots = loaded
    }

    /// Sample the pixel colour at the given point in global CoreGraphics space.
    func sampleColor(at screenPoint: CGPoint) -> PickedColor? {
        guard let snapshot = snapshot(containing: screenPoint),
              let pixel = pixelCoordinate(of: screenPoint, in: snapshot),
              snapshot.bytesPerPixel >= 3,
              let ptr = CFDataGetBytePtr(snapshot.data)
        else { return nil }

        let offset = pixel.y * snapshot.bytesPerRow + pixel.x * snapshot.bytesPerPixel
        guard offset + 2 < CFDataGetLength(snapshot.data) else { return nil }

        // SCScreenshotManager hands back BGRA.
        let b = CGFloat(ptr[offset]) / 255.0
        let g = CGFloat(ptr[offset + 1]) / 255.0
        let r = CGFloat(ptr[offset + 2]) / 255.0

        return PickedColor(nsColor: NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0))
    }

    /// Crop a magnified region around the given point for the loupe display.
    func captureLoupeRegion(at screenPoint: CGPoint, radius: Int) -> CGImage? {
        guard let snapshot = snapshot(containing: screenPoint),
              let center = pixelCoordinate(of: screenPoint, in: snapshot)
        else { return nil }

        let pixelRadius = Int((CGFloat(radius) * snapshot.scale).rounded())
        let cropRect = CGRect(
            x: center.x - pixelRadius,
            y: center.y - pixelRadius,
            width: pixelRadius * 2,
            height: pixelRadius * 2
        ).intersection(CGRect(x: 0, y: 0, width: snapshot.image.width, height: snapshot.image.height))

        guard cropRect.width >= 1, cropRect.height >= 1 else { return nil }
        return snapshot.image.cropping(to: cropRect)
    }

    private func snapshot(containing point: CGPoint) -> DisplaySnapshot? {
        snapshots.first { $0.frame.contains(point) } ?? snapshots.first
    }

    /// Global CoreGraphics point to pixel coordinates inside the snapshot. Both use a
    /// top-left origin, so this is an offset plus the display's scale.
    private func pixelCoordinate(of point: CGPoint, in snapshot: DisplaySnapshot) -> (x: Int, y: Int)? {
        let x = Int(((point.x - snapshot.frame.origin.x) * snapshot.scale).rounded(.down))
        let y = Int(((point.y - snapshot.frame.origin.y) * snapshot.scale).rounded(.down))
        guard x >= 0, y >= 0, x < snapshot.image.width, y < snapshot.image.height else { return nil }
        return (x, y)
    }
}
