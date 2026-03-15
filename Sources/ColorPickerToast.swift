// ColorPickerToast.swift
// MikaScreenSnap
//
// Mini toast notification for picked colors with auto-dismiss.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
enum ColorPickerToast {
    private static var currentPanel: NSPanel?

    static func show(color: PickedColor) {
        // Dismiss existing
        currentPanel?.orderOut(nil)
        currentPanel = nil

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces]

        let contentView = ToastView(frame: NSRect(x: 0, y: 0, width: 200, height: 40))
        contentView.pickedColor = color
        panel.contentView = contentView

        // Position near cursor
        let mouseLocation = NSEvent.mouseLocation
        panel.setFrameOrigin(NSPoint(x: mouseLocation.x - 100, y: mouseLocation.y + 20))

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        currentPanel = panel

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            panel.animator().alphaValue = 1.0
        }

        // Auto-dismiss after 2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { @MainActor in
            guard currentPanel === panel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                panel.animator().alphaValue = 0
            }, completionHandler: {
                MainActor.assumeIsolated {
                    panel.orderOut(nil)
                    if currentPanel === panel {
                        currentPanel = nil
                    }
                }
            })
        }
    }
}

@MainActor
private final class ToastView: NSView {
    var pickedColor: PickedColor?

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext, let color = pickedColor else { return }

        // Rounded background
        let bgPath = CGPath(roundedRect: bounds, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.85).cgColor)
        ctx.addPath(bgPath)
        ctx.fillPath()

        // Color circle
        let circleRect = NSRect(x: 10, y: 8, width: 24, height: 24)
        ctx.setFillColor(color.nsColor.cgColor)
        ctx.fillEllipse(in: circleRect)
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(1)
        ctx.strokeEllipse(in: circleRect)

        // Text
        let text = "Copied \(color.hex)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white,
        ]

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        text.draw(at: NSPoint(x: 42, y: 11), withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
    }
}
