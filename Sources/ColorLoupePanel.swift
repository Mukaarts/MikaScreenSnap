// ColorLoupePanel.swift
// MikaScreenSnap
//
// Screen-wide color picker with magnifying loupe and click-to-capture.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class ColorLoupeController {
    private var overlayPanels: [NSPanel] = []
    private var loupePanel: NSPanel?
    private var loupeView: LoupeView?
    private var globalMouseMonitor: Any?
    private var globalClickMonitor: Any?
    private var keyMonitor: Any?
    private weak var appState: AppState?
    private var onComplete: ((PickedColor) -> Void)?

    func start(appState: AppState, onComplete: @escaping (PickedColor) -> Void) {
        self.appState = appState
        self.onComplete = onComplete

        // Create fullscreen overlay panels for each screen
        for screen in NSScreen.screens {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.isOpaque = false
            panel.backgroundColor = NSColor.clear.withAlphaComponent(0.001)
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.ignoresMouseEvents = true
            panel.makeKeyAndOrderFront(nil)
            overlayPanels.append(panel)
        }

        // Create loupe panel
        let loupeSize: CGFloat = 160
        let loupePanelRect = NSRect(x: 0, y: 0, width: loupeSize, height: loupeSize + 50)
        let lPanel = NSPanel(
            contentRect: loupePanelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        lPanel.level = .screenSaver + 1
        lPanel.isOpaque = false
        lPanel.backgroundColor = .clear
        lPanel.hasShadow = true
        lPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        lPanel.ignoresMouseEvents = true

        let lView = LoupeView(frame: loupePanelRect)
        lPanel.contentView = lView
        self.loupeView = lView
        self.loupePanel = lPanel
        lPanel.makeKeyAndOrderFront(nil)

        // Mouse move monitor
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.updateLoupe()
            }
        }

        // Click monitor
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleClick(event: event)
            }
        }

        // Key monitor for ESC
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                if event.keyCode == 53 { // ESC
                    self?.cancel()
                }
            }
        }

        updateLoupe()
    }

    private func updateLoupe() {
        guard let loupePanel, let loupeView else { return }

        let mouseLocation = NSEvent.mouseLocation
        // Convert to screen coordinates (CGDisplay uses top-left origin)
        guard let screen = NSScreen.main else { return }
        let screenHeight = screen.frame.height
        let cgPoint = CGPoint(x: mouseLocation.x, y: screenHeight - mouseLocation.y)

        let loupeWindowIDs = [loupePanel].compactMap { CGWindowID($0.windowNumber) }

        // Sample color at cursor
        if let pickedColor = ColorPickerEngine.sampleColor(at: cgPoint, excluding: loupeWindowIDs) {
            loupeView.currentColor = pickedColor
        }

        // Capture loupe region
        if let loupeImage = ColorPickerEngine.captureLoupeRegion(at: cgPoint, radius: 10, excluding: loupeWindowIDs) {
            loupeView.loupeImage = loupeImage
        }

        loupeView.needsDisplay = true

        // Position loupe panel near cursor (offset to avoid cursor)
        let offsetX: CGFloat = 20
        let offsetY: CGFloat = 20
        loupePanel.setFrameOrigin(NSPoint(
            x: mouseLocation.x + offsetX,
            y: mouseLocation.y - loupePanel.frame.height - offsetY
        ))
    }

    private func handleClick(event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        let screenHeight = screen.frame.height
        let cgPoint = CGPoint(x: mouseLocation.x, y: screenHeight - mouseLocation.y)

        let loupeWindowIDs = loupePanel.map { [CGWindowID($0.windowNumber)] } ?? []

        guard let pickedColor = ColorPickerEngine.sampleColor(at: cgPoint, excluding: loupeWindowIDs) else {
            cancel()
            return
        }

        let isShiftHeld = event.modifierFlags.contains(.shift)

        // Copy HEX to clipboard
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(pickedColor.hex, forType: .string)

        // Add to color history
        appState?.colorHistory.addColor(pickedColor.hex)

        if isShiftHeld {
            // Add to palette
            appState?.colorHistory.addToPalette(pickedColor.hex)
        }

        cleanup()
        onComplete?(pickedColor)

        // Show toast
        ColorPickerToast.show(color: pickedColor)
    }

    func cancel() {
        cleanup()
    }

    private func cleanup() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        for panel in overlayPanels {
            panel.orderOut(nil)
        }
        overlayPanels.removeAll()

        loupePanel?.orderOut(nil)
        loupePanel = nil
        loupeView = nil
    }
}

// MARK: - Loupe View

@MainActor
private final class LoupeView: NSView {
    var loupeImage: CGImage?
    var currentColor: PickedColor?

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let loupeSize: CGFloat = 140
        let loupeRect = NSRect(x: (bounds.width - loupeSize) / 2, y: bounds.height - loupeSize - 10, width: loupeSize, height: loupeSize)

        // Draw loupe circle
        ctx.saveGState()

        let clipPath = CGPath(ellipseIn: loupeRect, transform: nil)
        ctx.addPath(clipPath)
        ctx.clip()

        if let image = loupeImage {
            ctx.interpolationQuality = .none
            ctx.draw(image, in: loupeRect)
        } else {
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(loupeRect)
        }

        ctx.restoreGState()

        // Draw crosshair
        let centerX = loupeRect.midX
        let centerY = loupeRect.midY
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.8).cgColor)
        ctx.setLineWidth(1)

        // Horizontal line
        ctx.move(to: CGPoint(x: centerX - 8, y: centerY))
        ctx.addLine(to: CGPoint(x: centerX + 8, y: centerY))
        ctx.strokePath()

        // Vertical line
        ctx.move(to: CGPoint(x: centerX, y: centerY - 8))
        ctx.addLine(to: CGPoint(x: centerX, y: centerY + 8))
        ctx.strokePath()

        // Draw border ring
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.setLineWidth(3)
        ctx.strokeEllipse(in: loupeRect.insetBy(dx: 1.5, dy: 1.5))

        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1)
        ctx.strokeEllipse(in: loupeRect.insetBy(dx: 0.5, dy: 0.5))

        // Draw color info below loupe
        if let color = currentColor {
            let infoY: CGFloat = 8
            let bgRect = NSRect(x: 10, y: infoY, width: bounds.width - 20, height: 38)

            // Background pill
            let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.75).cgColor)
            ctx.addPath(bgPath)
            ctx.fillPath()

            // Color swatch
            let swatchRect = NSRect(x: 16, y: infoY + 6, width: 26, height: 26)
            ctx.setFillColor(color.nsColor.cgColor)
            ctx.fillEllipse(in: swatchRect)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.5).cgColor)
            ctx.setLineWidth(1)
            ctx.strokeEllipse(in: swatchRect)

            // HEX text
            let hexString = color.hex as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor.white,
            ]

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
            hexString.draw(at: NSPoint(x: 48, y: infoY + 11), withAttributes: attrs)
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}
