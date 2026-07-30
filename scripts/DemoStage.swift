#!/usr/bin/env swift
// DemoStage.swift
// MikaScreenSnap
//
// Displays the generated demo canvas full-screen on the primary display as a
// borderless window, so marketing screenshots are taken against controlled,
// non-private content instead of the real desktop.
//
// The window sits at normal level, which keeps the menu bar reachable — the
// capture script needs to click the app's menu bar item.
//
// Usage: swift scripts/DemoStage.swift installer/demo-canvas.png
//        (runs until terminated)

import AppKit

let args = Array(CommandLine.arguments.dropFirst())
guard let path = args.first, let image = NSImage(contentsOfFile: path) else {
    FileHandle.standardError.write("usage: DemoStage.swift <image>\n".data(using: .utf8)!)
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// The primary display is the one anchored at the origin — that is where the
// menu bar lives on this setup.
let screen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens[0]

let window = NSWindow(
    contentRect: screen.frame,
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
window.setFrame(screen.frame, display: true)
// Floating keeps the stage above ordinary windows so nothing from the real
// desktop leaks into a capture. The app's own overlays sit at .screenSaver and
// the menu bar higher still, so both stay reachable.
window.level = .floating
window.isOpaque = true
window.hasShadow = false
window.ignoresMouseEvents = false
window.collectionBehavior = [.stationary, .ignoresCycle]

let imageView = NSImageView(frame: NSRect(origin: .zero, size: screen.frame.size))
imageView.image = image
imageView.imageScaling = .scaleAxesIndependently
imageView.autoresizingMask = [.width, .height]

let container = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
container.wantsLayer = true
container.layer?.backgroundColor = NSColor.white.cgColor
container.addSubview(imageView)
window.contentView = container

window.orderFrontRegardless()

signal(SIGTERM) { _ in exit(0) }
signal(SIGINT) { _ in exit(0) }

app.run()
