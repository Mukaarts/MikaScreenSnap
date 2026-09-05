#!/usr/bin/env swift
// GenerateDemoCanvas.swift
// MikaScreenSnap
//
// Generates a neutral full-screen demo canvas used as the stage for marketing
// screenshots. Nothing here is real data — it exists so product screenshots
// never expose the developer's actual desktop.
//
// The canvas deliberately contains material for every feature we showcase:
//   - crisp body text          -> OCR capture
//   - flat brand color swatches -> color picker / loupe
//   - hard-edged cards          -> measurement tool
//   - a "sensitive" credentials row -> blur / pixelate demo
//   - open space                -> arrows, highlights, text annotations
//   - photographic plates       -> a document that reads like a real one
//
// Usage: swift scripts/GenerateDemoCanvas.swift

import AppKit
import CoreGraphics
import Foundation

// MARK: - Colors

func color(hex: String) -> NSColor {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var rgb: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&rgb)
    let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let b = CGFloat(rgb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
}

// Brand palette — mirrors Sources/MikaPlusColors.swift
let tealPrimary = color(hex: "#1D9E75")
let tealLight = color(hex: "#5DCAA5")
let tealLightest = color(hex: "#9FE1CB")
let tealSurface = color(hex: "#E1F5EE")
let darkBg = color(hex: "#1A1A2E")
let darkBgDeep = color(hex: "#0F0F1A")
let destructive = color(hex: "#E24B4A")

// Page chrome
let pageBg = color(hex: "#EEF3F1")
let cardBg = color(hex: "#FFFFFF")
let ink = color(hex: "#14201C")
let inkSoft = color(hex: "#5A6B65")
let hairline = color(hex: "#D8E2DE")

// MARK: - Canvas geometry

let W: CGFloat = 3840
let H: CGFloat = 2160

/// Converts top-left anchored coordinates into CoreGraphics bottom-left space.
func tl(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: H - y - h, width: w, height: h)
}

// MARK: - Drawing helpers

func fillRounded(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    color.setFill()
    path.fill()
}

func strokeRounded(_ rect: NSRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    let path = NSBezierPath(roundedRect: rect.insetBy(dx: width / 2, dy: width / 2),
                            xRadius: radius, yRadius: radius)
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func attrs(size: CGFloat,
           weight: NSFont.Weight = .regular,
           color: NSColor = ink,
           tracking: CGFloat = 0,
           lineHeight: CGFloat? = nil,
           mono: Bool = false) -> [NSAttributedString.Key: Any] {
    let font: NSFont = mono
        ? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        : NSFont.systemFont(ofSize: size, weight: weight)
    var result: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
    ]
    if tracking != 0 { result[.kern] = tracking }
    if let lineHeight {
        let para = NSMutableParagraphStyle()
        para.minimumLineHeight = lineHeight
        para.maximumLineHeight = lineHeight
        result[.paragraphStyle] = para
    }
    return result
}

func draw(_ text: String, in rect: NSRect, _ attributes: [NSAttributedString.Key: Any]) {
    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

// MARK: - Photography

// The only pixels on this canvas that aren't drawn here. Everything else is code
// and therefore reproducible; these two plates live in the repository instead.
let imageryDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("AppStore/assets/imagery")

/// Loads one imagery plate, or stops.
///
/// No silent fallback to a drawn placeholder: the canvas is the stage for every
/// store screenshot, and a run that quietly produced a different document would
/// ship that difference to the App Store without anyone noticing.
func plate(_ name: String) -> NSImage {
    let url = imageryDir.appendingPathComponent("\(name).jpg")
    guard let image = NSImage(contentsOf: url) else {
        print("ERROR: imagery plate missing: \(url.path)")
        exit(1)
    }
    return image
}

/// Draws an image so it covers `rect` completely, cropping the overflowing axis
/// centred. The plate keeps its aspect ratio whatever the slot's ratio is.
func drawFilling(_ image: NSImage, in rect: NSRect, radius: CGFloat) {
    let size = image.size
    guard size.width > 0, size.height > 0 else { return }
    let scale = max(rect.width / size.width, rect.height / size.height)
    let w = size.width * scale, h = size.height * scale
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    image.draw(in: NSRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h),
               from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.current?.restoreGraphicsState()
}

// MARK: - Canvas

func generateCanvas() -> NSImage {
    let image = NSImage(size: NSSize(width: W, height: H))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }

    // Page background with a very soft teal wash in the top-right
    pageBg.setFill()
    NSRect(x: 0, y: 0, width: W, height: H).fill()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let washColors = [
        tealLightest.withAlphaComponent(0.35).cgColor,
        tealLightest.withAlphaComponent(0.0).cgColor,
    ] as CFArray
    if let wash = CGGradient(colorsSpace: colorSpace, colors: washColors, locations: [0, 1]) {
        ctx.drawRadialGradient(wash,
                               startCenter: CGPoint(x: W * 0.82, y: H * 0.88), startRadius: 0,
                               endCenter: CGPoint(x: W * 0.82, y: H * 0.88), endRadius: 1500,
                               options: [])
    }

    let margin: CGFloat = 200

    // MARK: Header

    draw("DESIGN SYSTEM", in: tl(margin, 150, 900, 48),
         attrs(size: 34, weight: .semibold, color: tealPrimary, tracking: 6))

    draw("Component Review — Release 4.2", in: tl(margin, 210, 2200, 130),
         attrs(size: 96, weight: .bold, color: ink, tracking: -2))

    draw("Draft shared for annotation. Mark anything that needs a second pass before we ship.",
         in: tl(margin, 350, 2400, 60),
         attrs(size: 40, weight: .regular, color: inkSoft))

    // Header rule
    hairline.setFill()
    tl(margin, 450, W - margin * 2, 3).fill()

    // MARK: Left column — body copy (OCR target)
    //
    // Everything the screenshots need sits above y = 1400 px, which maps to the
    // upper portion of the screen. That keeps the capture region clear of the
    // on-screen keyboard panel that floats over the lower right of the display.

    let colX = margin
    let colW: CGFloat = 1560

    draw("Typography", in: tl(colX, 530, colW, 60),
         attrs(size: 52, weight: .semibold, color: ink))

    let para1 = """
    The interface type scale is built on a single ratio so that headings, body \
    copy and captions stay in proportion at every window size. Body text is set \
    at seventeen points with generous leading.
    """
    draw(para1, in: tl(colX, 630, colW, 260),
         attrs(size: 38, weight: .regular, color: ink, lineHeight: 62))

    // Sensitive callout — the blur / pixelate target. All values are fictional;
    // .invalid is a reserved TLD so the address can never resolve.
    let sensRect = tl(colX, 900, colW, 200)
    fillRounded(sensRect, radius: 24, color: darkBg)
    draw("STAGING ACCESS — DO NOT SHARE", in: tl(colX + 44, 936, colW - 88, 44),
         attrs(size: 28, weight: .semibold, color: tealLightest, tracking: 4))
    draw("billing@acme-demo.invalid", in: tl(colX + 44, 990, colW - 88, 50),
         attrs(size: 36, weight: .medium, color: .white, mono: true))
    draw("sk_live_4f8b2c9e1a7d3f60b5e8", in: tl(colX + 44, 1040, colW - 88, 50),
         attrs(size: 36, weight: .medium, color: .white, mono: true))

    draw("Spacing", in: tl(colX, 1170, colW, 60),
         attrs(size: 52, weight: .semibold, color: ink))

    let para2 = """
    Every measurement is a multiple of four. Cards use twenty-four points of \
    inner padding, sections are separated by forty-eight, and the outer grid \
    margin stays fixed at sixty-four points across all breakpoints.
    """
    draw(para2, in: tl(colX, 1270, colW, 260),
         attrs(size: 38, weight: .regular, color: ink, lineHeight: 62))

    // --- Imagery (the photographic plates)
    //
    // Took the place of a third body paragraph. Two paragraphs above are already
    // more OCR material than any capture region uses, and a design system review
    // that shows no imagery at all reads like a wireframe, not like a document
    // somebody would actually annotate.
    draw("Imagery", in: tl(colX, 1560, colW, 60),
         attrs(size: 52, weight: .semibold, color: ink))

    let plateGap: CGFloat = 40
    let plateW = (colW - plateGap) / 2
    let plateH: CGFloat = 370
    for (i, name) in ["a", "b"].enumerated() {
        let rect = tl(colX + CGFloat(i) * (plateW + plateGap), 1650, plateW, plateH)
        drawFilling(plate(name), in: rect, radius: 24)
        strokeRounded(rect, radius: 24, color: hairline, width: 2)
    }

    // MARK: Right column — swatches, cards, chart

    let rightX = margin + colW + 220
    let rightW = W - rightX - margin

    // --- Color swatches (color picker target)
    draw("Palette", in: tl(rightX, 530, rightW, 60),
         attrs(size: 52, weight: .semibold, color: ink))

    let swatches: [(NSColor, String)] = [
        (tealPrimary, "#1D9E75"),
        (tealLight, "#5DCAA5"),
        (tealLightest, "#9FE1CB"),
        (tealSurface, "#E1F5EE"),
        (darkBg, "#1A1A2E"),
        (destructive, "#E24B4A"),
    ]
    let swatchGap: CGFloat = 28
    let swatchW = (rightW - swatchGap * CGFloat(swatches.count - 1)) / CGFloat(swatches.count)
    for (i, entry) in swatches.enumerated() {
        let x = rightX + CGFloat(i) * (swatchW + swatchGap)
        // Flat, unshaded fill so a picked pixel matches the label exactly
        fillRounded(tl(x, 620, swatchW, 200), radius: 20, color: entry.0)
        draw(entry.1, in: tl(x, 840, swatchW, 40),
             attrs(size: 28, weight: .medium, color: inkSoft, mono: true))
    }

    // --- Metric cards (measurement target: crisp, known-size rectangles)
    let cards: [(String, String, String)] = [
        ("Components", "148", "42 updated this cycle"),
        ("Tokens", "312", "colour, type, spacing"),
        ("Coverage", "94%", "documented in Storybook"),
    ]
    let cardGap: CGFloat = 40
    let cardW = (rightW - cardGap * CGFloat(cards.count - 1)) / CGFloat(cards.count)
    let cardY: CGFloat = 920
    let cardH: CGFloat = 300
    for (i, card) in cards.enumerated() {
        let x = rightX + CGFloat(i) * (cardW + cardGap)
        let rect = tl(x, cardY, cardW, cardH)
        fillRounded(rect, radius: 24, color: cardBg)
        strokeRounded(rect, radius: 24, color: hairline, width: 2)
        draw(card.0, in: tl(x + 40, cardY + 40, cardW - 80, 40),
             attrs(size: 30, weight: .medium, color: inkSoft, tracking: 1))
        draw(card.1, in: tl(x + 40, cardY + 90, cardW - 80, 110),
             attrs(size: 84, weight: .bold, color: ink, tracking: -1))
        draw(card.2, in: tl(x + 40, cardY + 210, cardW - 80, 50),
             attrs(size: 28, weight: .regular, color: inkSoft))
    }

    // --- Adoption chart
    draw("Adoption by platform", in: tl(rightX, 1300, rightW, 60),
         attrs(size: 52, weight: .semibold, color: ink))

    let bars: [(String, CGFloat)] = [
        ("macOS", 0.92),
        ("iPadOS", 0.74),
        ("Web", 0.61),
        ("Windows", 0.38),
    ]
    let chartY: CGFloat = 1400
    let barH: CGFloat = 64
    let barGap: CGFloat = 34
    let labelW: CGFloat = 260
    let trackW = rightW - labelW - 140
    for (i, bar) in bars.enumerated() {
        let by = chartY + CGFloat(i) * (barH + barGap)
        draw(bar.0, in: tl(rightX, by + 14, labelW, 44),
             attrs(size: 34, weight: .medium, color: inkSoft))
        let track = tl(rightX + labelW, by, trackW, barH)
        fillRounded(track, radius: barH / 2, color: cardBg)
        let fill = tl(rightX + labelW, by, trackW * bar.1, barH)
        fillRounded(fill, radius: barH / 2, color: i == 0 ? tealPrimary : tealLight)
        draw("\(Int(bar.1 * 100))%",
             in: tl(rightX + labelW + trackW + 30, by + 14, 130, 44),
             attrs(size: 34, weight: .semibold, color: ink, mono: true))
    }

    // MARK: Footer

    draw("Internal draft · not for distribution", in: tl(margin, 2065, 1600, 46),
         attrs(size: 30, weight: .regular, color: inkSoft))

    return image
}

// MARK: - Save

func savePNG(_ image: NSImage, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(W),
        pixelsHigh: Int(H),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = image.size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: W, height: H),
               from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: could not encode PNG")
        exit(1)
    }
    do {
        try png.write(to: url)
        print("  Created: \(url.path) (\(Int(W))x\(Int(H)))")
    } catch {
        print("ERROR: \(error.localizedDescription)")
        exit(1)
    }
}

// MARK: - Main

let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let installerDir = projectDir.appendingPathComponent("installer")
try FileManager.default.createDirectory(at: installerDir, withIntermediateDirectories: true)

print("Generating demo canvas...")
savePNG(generateCanvas(), to: installerDir.appendingPathComponent("demo-canvas.png"))
print("Done.")
