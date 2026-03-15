#!/usr/bin/env swift
// GenerateIcon.swift
// MikaScreenSnap
//
// Standalone script to generate AppIcon.icns and MenubarIconTemplate PNGs.
// Usage: swift Scripts/GenerateIcon.swift

import AppKit
import CoreGraphics
import Foundation

// MARK: - Color Helpers

func color(hex: String) -> NSColor {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var rgb: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&rgb)
    let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let b = CGFloat(rgb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
}

let tealPrimary = color(hex: "#1D9E75")
let tealLight = color(hex: "#5DCAA5")
let darkBg = color(hex: "#1A1A2E")
let darkBgDeep = color(hex: "#0F0F1A")

// MARK: - App Icon Generator

func generateAppIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Background gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [darkBgDeep.cgColor, darkBg.cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0, 1])!

    // Superellipse mask (rounded rect with ~22% corner radius)
    let cornerRadius = s * 0.22
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.addPath(path)
    ctx.clip()

    ctx.drawLinearGradient(gradient, start: CGPoint(x: s / 2, y: s), end: CGPoint(x: s / 2, y: 0), options: [])

    // Viewfinder frame — teal gradient stroke, ~55% of icon
    let viewfinderSize = s * 0.55
    let viewfinderOrigin = (s - viewfinderSize) / 2
    let viewfinderRect = CGRect(x: viewfinderOrigin, y: viewfinderOrigin, width: viewfinderSize, height: viewfinderSize)
    let cornerLen = viewfinderSize * 0.3
    let strokeWidth = max(s * 0.035, 1.5)

    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)

    // Use teal gradient colors for the viewfinder
    let tealGradColors = [tealLight.cgColor, tealPrimary.cgColor] as CFArray
    let tealGrad = CGGradient(colorsSpace: colorSpace, colors: tealGradColors, locations: [0, 1])!

    // Draw viewfinder corners as clipped gradient
    ctx.saveGState()
    let viewfinderPath = CGMutablePath()

    // Top-left corner
    viewfinderPath.move(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.minY + cornerLen))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.minY))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.minX + cornerLen, y: viewfinderRect.minY))

    // Top-right corner
    viewfinderPath.move(to: CGPoint(x: viewfinderRect.maxX - cornerLen, y: viewfinderRect.minY))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.minY))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.minY + cornerLen))

    // Bottom-right corner
    viewfinderPath.move(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.maxY - cornerLen))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.maxY))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.maxX - cornerLen, y: viewfinderRect.maxY))

    // Bottom-left corner
    viewfinderPath.move(to: CGPoint(x: viewfinderRect.minX + cornerLen, y: viewfinderRect.maxY))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.maxY))
    viewfinderPath.addLine(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.maxY - cornerLen))

    // Stroke the viewfinder with gradient
    let strokedPath = viewfinderPath.copy(strokingWithWidth: strokeWidth, lineCap: .round, lineJoin: .miter, miterLimit: 10)
    ctx.addPath(strokedPath)
    ctx.clip()
    ctx.drawLinearGradient(tealGrad, start: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.maxY), end: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.minY), options: [])
    ctx.restoreGState()

    // Center glow — 3 concentric circles
    let center = CGPoint(x: s / 2, y: s / 2)
    let glowRadius = s * 0.06

    // Outer glow (15% opacity)
    ctx.setFillColor(tealLight.withAlphaComponent(0.15).cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - glowRadius * 3, y: center.y - glowRadius * 3, width: glowRadius * 6, height: glowRadius * 6))

    // Middle glow (30% opacity)
    ctx.setFillColor(tealLight.withAlphaComponent(0.3).cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - glowRadius * 2, y: center.y - glowRadius * 2, width: glowRadius * 4, height: glowRadius * 4))

    // Center dot (100% opacity)
    ctx.setFillColor(tealLight.cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2))

    // M+ Badge — pill shape bottom-right
    let badgeHeight = s * 0.18
    let badgeWidth = s * 0.28
    let badgePadding = s * 0.1
    let badgeRect = CGRect(
        x: s - badgeWidth - badgePadding,
        y: badgePadding,
        width: badgeWidth,
        height: badgeHeight
    )
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: badgeHeight / 2, cornerHeight: badgeHeight / 2, transform: nil)
    ctx.addPath(badgePath)
    ctx.setFillColor(tealPrimary.cgColor)
    ctx.fillPath()

    // "M+" text in badge
    let fontSize = badgeHeight * 0.6
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font as Any,
        .foregroundColor: NSColor.white,
    ]
    let attrStr = NSAttributedString(string: "M+", attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let textBounds = CTLineGetBoundsWithOptions(line, [])
    let textX = badgeRect.midX - textBounds.width / 2 - textBounds.origin.x
    let textY = badgeRect.midY - textBounds.height / 2 - textBounds.origin.y

    ctx.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, ctx)

    image.unlockFocus()
    return image
}

// MARK: - Menubar Icon Generator

func generateMenubarIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Black on transparent (template image convention)
    ctx.setStrokeColor(NSColor.black.cgColor)
    ctx.setFillColor(NSColor.black.cgColor)

    let strokeWidth: CGFloat = max(s * 0.083, 1.5)  // ~1.5px at 18, ~3px at 36
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)

    // Viewfinder corners — brackets at 4 corners
    let padding = s * 0.1
    let viewfinderRect = CGRect(x: padding, y: padding, width: s - padding * 2, height: s - padding * 2)
    let cornerLen = (s - padding * 2) * 0.3

    // Top-left
    ctx.move(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.minY + cornerLen))
    ctx.addLine(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.minY))
    ctx.addLine(to: CGPoint(x: viewfinderRect.minX + cornerLen, y: viewfinderRect.minY))

    // Top-right
    ctx.move(to: CGPoint(x: viewfinderRect.maxX - cornerLen, y: viewfinderRect.minY))
    ctx.addLine(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.minY))
    ctx.addLine(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.minY + cornerLen))

    // Bottom-right
    ctx.move(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.maxY - cornerLen))
    ctx.addLine(to: CGPoint(x: viewfinderRect.maxX, y: viewfinderRect.maxY))
    ctx.addLine(to: CGPoint(x: viewfinderRect.maxX - cornerLen, y: viewfinderRect.maxY))

    // Bottom-left
    ctx.move(to: CGPoint(x: viewfinderRect.minX + cornerLen, y: viewfinderRect.maxY))
    ctx.addLine(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.maxY))
    ctx.addLine(to: CGPoint(x: viewfinderRect.minX, y: viewfinderRect.maxY - cornerLen))

    ctx.strokePath()

    // Center dot
    let dotRadius = s * 0.083  // ~1.5px at 18, ~3px at 36
    let center = CGPoint(x: s / 2, y: s / 2)
    ctx.fillEllipse(in: CGRect(
        x: center.x - dotRadius,
        y: center.y - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
    ))

    image.unlockFocus()
    return image
}

// MARK: - PNG Export

func savePNG(_ image: NSImage, to url: URL) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("ERROR: Failed to create PNG for \(url.lastPathComponent)")
        return
    }
    do {
        try pngData.write(to: url)
        print("  Created: \(url.lastPathComponent)")
    } catch {
        print("ERROR: \(error.localizedDescription)")
    }
}

func savePNGAtSize(_ image: NSImage, pixelSize: Int, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
               from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: Failed to create PNG for \(url.lastPathComponent)")
        return
    }
    do {
        try pngData.write(to: url)
        print("  Created: \(url.lastPathComponent)")
    } catch {
        print("ERROR: \(error.localizedDescription)")
    }
}

// MARK: - Main

let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesDir = projectDir.appendingPathComponent("Resources")

// Ensure Resources directory exists
try FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)

// --- Generate App Icon ---
print("Generating App Icon...")

let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconsetDir)
try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// Icon sizes per Apple spec
let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

// Generate at 1024 and scale down for all sizes
let masterIcon = generateAppIcon(size: 1024)

for entry in iconSizes {
    let url = iconsetDir.appendingPathComponent(entry.name)
    savePNGAtSize(masterIcon, pixelSize: entry.pixels, to: url)
}

// Convert to .icns
print("Converting to .icns...")
let icnsPath = resourcesDir.appendingPathComponent("AppIcon.icns").path
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath]
try task.run()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("  Created: AppIcon.icns")
    // Clean up iconset
    try? FileManager.default.removeItem(at: iconsetDir)
} else {
    print("ERROR: iconutil failed with status \(task.terminationStatus)")
}

// --- Generate Menubar Icons ---
print("Generating Menubar Icons...")

let menubar18 = generateMenubarIcon(size: 18)
savePNG(menubar18, to: resourcesDir.appendingPathComponent("MenubarIconTemplate.png"))

let menubar36 = generateMenubarIcon(size: 36)
savePNG(menubar36, to: resourcesDir.appendingPathComponent("MenubarIconTemplate@2x.png"))

print("\nDone! Generated assets in Resources/")
