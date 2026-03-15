#!/usr/bin/env swift
// GenerateDMGBackground.swift
// MikaScreenSnap
//
// Generates DMG installer background images (1x and 2x).
// Usage: swift scripts/GenerateDMGBackground.swift

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

let darkBgDeep = color(hex: "#0F0F1A")
let darkBg = color(hex: "#1A1A2E")
let tealPrimary = color(hex: "#1D9E75")
let tealLight = color(hex: "#5DCAA5")
let tealAccent = color(hex: "#9FE1CB")

// MARK: - Radial glow helper

func drawRadialGlow(ctx: CGContext, center: CGPoint, radius: CGFloat, color: NSColor, alpha: CGFloat) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let comps = color.cgColor.components ?? [0, 0, 0, 0]
    let r = comps.count >= 3 ? comps[0] : 0
    let g = comps.count >= 3 ? comps[1] : 0
    let b = comps.count >= 3 ? comps[2] : 0
    let colors = [
        CGColor(srgbRed: r, green: g, blue: b, alpha: alpha),
        CGColor(srgbRed: r, green: g, blue: b, alpha: 0),
    ] as CFArray
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else { return }
    ctx.saveGState()
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    ctx.restoreGState()
}

// MARK: - Background Generator

func generateDMGBackground(width: Int, height: Int) -> NSImage {
    let w = CGFloat(width)
    let h = CGFloat(height)
    let image = NSImage(size: NSSize(width: w, height: h))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Background gradient (top-to-bottom)
    let gradientColors = [darkBgDeep.cgColor, darkBg.cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: w / 2, y: h), end: CGPoint(x: w / 2, y: 0), options: [])

    // Icon positions (CG coordinates: y=0 is bottom)
    // create-dmg places icons at (150, 200) and (450, 200) in Finder coords (y=0 top)
    // In CG coords: y = height - finderY = 400 - 200 = 200
    let iconY = h - 200.0
    let appX: CGFloat = 150.0
    let appsX: CGFloat = 450.0

    // Subtle radial glows behind icon positions (soft, small)
    drawRadialGlow(ctx: ctx, center: CGPoint(x: appX, y: iconY), radius: 70, color: tealLight, alpha: 0.06)
    drawRadialGlow(ctx: ctx, center: CGPoint(x: appsX, y: iconY), radius: 70, color: tealLight, alpha: 0.06)

    // Arrow from app icon area to Applications area
    let arrowStartX: CGFloat = 220
    let arrowEndX: CGFloat = 380
    let arrowY = iconY

    ctx.saveGState()
    let arrowPath = CGMutablePath()
    arrowPath.move(to: CGPoint(x: arrowStartX, y: arrowY))
    arrowPath.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
    // Arrowhead
    let headLen: CGFloat = 14
    let headWidth: CGFloat = 8
    arrowPath.move(to: CGPoint(x: arrowEndX - headLen, y: arrowY + headWidth))
    arrowPath.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
    arrowPath.addLine(to: CGPoint(x: arrowEndX - headLen, y: arrowY - headWidth))

    let strokeWidth: CGFloat = 2.5
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Stroke arrow with teal gradient
    let strokedArrow = arrowPath.copy(strokingWithWidth: strokeWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)
    ctx.addPath(strokedArrow)
    ctx.clip()
    let tealGradColors = [tealLight.cgColor, tealPrimary.cgColor] as CFArray
    let tealGrad = CGGradient(colorsSpace: colorSpace, colors: tealGradColors, locations: [0, 1])!
    ctx.drawLinearGradient(tealGrad, start: CGPoint(x: arrowStartX, y: arrowY), end: CGPoint(x: arrowEndX, y: arrowY), options: [])
    ctx.restoreGState()

    // "Drag to install" text — positioned below the icons
    let dragText = "Drag to install"
    let dragFont = CTFontCreateWithName("Helvetica Neue Bold" as CFString, 14.0, nil)
    let dragAttrs: [NSAttributedString.Key: Any] = [
        .font: dragFont as Any,
        .foregroundColor: tealAccent.withAlphaComponent(0.8),
    ]
    let dragStr = NSAttributedString(string: dragText, attributes: dragAttrs)
    let dragLine = CTLineCreateWithAttributedString(dragStr)
    let dragBounds = CTLineGetBoundsWithOptions(dragLine, [])
    let dragX = w / 2 - dragBounds.width / 2 - dragBounds.origin.x
    // Finder y=310 → CG y = 400-310 = 90
    let dragY: CGFloat = h - 310

    ctx.textPosition = CGPoint(x: dragX, y: dragY)
    CTLineDraw(dragLine, ctx)

    // Version text
    let version = "v1.0"
    let versionFont = CTFontCreateWithName("Helvetica Neue" as CFString, 11.0, nil)
    let versionAttrs: [NSAttributedString.Key: Any] = [
        .font: versionFont as Any,
        .foregroundColor: tealLight.withAlphaComponent(0.35),
    ]
    let versionStr = NSAttributedString(string: version, attributes: versionAttrs)
    let versionLine = CTLineCreateWithAttributedString(versionStr)
    let versionBounds = CTLineGetBoundsWithOptions(versionLine, [])
    let versionX = w / 2 - versionBounds.width / 2 - versionBounds.origin.x
    // Finder y=335 → CG y = 400-335 = 65
    let versionY: CGFloat = h - 335

    ctx.textPosition = CGPoint(x: versionX, y: versionY)
    CTLineDraw(versionLine, ctx)

    image.unlockFocus()
    return image
}

// MARK: - Save PNG at pixel dimensions

func savePNG(_ image: NSImage, pixelWidth: Int, pixelHeight: Int, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelWidth,
        pixelsHigh: pixelHeight,
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
    image.draw(in: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
               from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: Failed to create PNG for \(url.lastPathComponent)")
        return
    }
    do {
        try pngData.write(to: url)
        print("  Created: \(url.lastPathComponent) (\(pixelWidth)x\(pixelHeight))")
    } catch {
        print("ERROR: \(error.localizedDescription)")
    }
}

// MARK: - Main

let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let installerDir = projectDir.appendingPathComponent("installer")

// Ensure installer directory exists
try FileManager.default.createDirectory(at: installerDir, withIntermediateDirectories: true)

print("Generating DMG background images...")

// Generate 1x (600x400)
let bg1x = generateDMGBackground(width: 600, height: 400)
savePNG(bg1x, pixelWidth: 600, pixelHeight: 400,
        to: installerDir.appendingPathComponent("dmg-background.png"))

// Generate 2x (1200x800)
let bg2x = generateDMGBackground(width: 600, height: 400)
savePNG(bg2x, pixelWidth: 1200, pixelHeight: 800,
        to: installerDir.appendingPathComponent("dmg-background@2x.png"))

print("\nDone! Generated DMG backgrounds in installer/")
