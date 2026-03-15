// MeasurementOverlay.swift
// MikaScreenSnap
//
// Fullscreen measurement overlay for standalone pixel measurement.
// Two modes: point-to-point (click A -> click B) and rectangle (drag).
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class MeasurementOverlayController {
    private var panels: [MeasurementPanel] = []
    private var keyMonitor: Any?

    func start() {
        dismiss()

        for screen in NSScreen.screens {
            let panel = MeasurementPanel(screen: screen) { [weak self] in
                self?.dismiss()
            }
            panel.makeKeyAndOrderFront(nil)
            panels.append(panel)
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.dismiss()
                return nil
            }
            if event.keyCode == 49 { // Space = toggle px/pt
                for panel in self?.panels ?? [] {
                    (panel.contentView as? MeasurementOverlayView)?.toggleUnit()
                }
                return nil
            }
            return event
        }
    }

    func dismiss() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
    }
}

// MARK: - Panel

@MainActor
private final class MeasurementPanel: NSPanel {
    init(screen: NSScreen, onDismiss: @escaping () -> Void) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hasShadow = false

        let view = MeasurementOverlayView(frame: screen.frame, screenScale: screen.backingScaleFactor, onDismiss: onDismiss)
        contentView = view
    }
}

// MARK: - Overlay View

@MainActor
private final class MeasurementOverlayView: NSView {
    private var pointA: CGPoint?
    private var pointB: CGPoint?
    private var isDragging = false
    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?
    private var showInPoints = false
    private let screenScale: CGFloat
    private let onDismiss: () -> Void

    init(frame: NSRect, screenScale: CGFloat, onDismiss: @escaping () -> Void) {
        self.screenScale = screenScale
        self.onDismiss = onDismiss
        super.init(frame: frame)

        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    func toggleUnit() {
        showInPoints.toggle()
        needsDisplay = true
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if pointA == nil {
            pointA = point
            isDragging = true
            dragStart = point
        } else if pointB == nil {
            pointB = point
            isDragging = false
        } else {
            // Reset
            pointA = point
            pointB = nil
            isDragging = true
            dragStart = point
            dragCurrent = nil
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragCurrent = point
        isDragging = true
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if isDragging, let start = dragStart {
            let dx = abs(point.x - start.x)
            let dy = abs(point.y - start.y)

            if dx > 3 || dy > 3 {
                // Rectangle mode
                pointA = start
                pointB = point
                dragCurrent = nil
                isDragging = false
            } else {
                // Point-to-point: waiting for second click
                isDragging = false
                dragCurrent = nil
            }
        }
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        if pointA != nil && pointB == nil && !isDragging {
            dragCurrent = convert(event.locationInWindow, from: nil)
            needsDisplay = true
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Semi-transparent overlay
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.15).cgColor)
        ctx.fill(bounds)

        let factor = showInPoints ? 1.0 : screenScale

        if let a = pointA {
            if let b = pointB ?? dragCurrent {
                let dx = abs(b.x - a.x)
                let dy = abs(b.y - a.y)

                // Check if it's a rectangle drag or point-to-point
                let isRect = (dragStart != nil && pointB != nil && dx > 3 && dy > 3)
                    || (isDragging && dx > 3 && dy > 3)

                if isRect {
                    drawRectMeasurement(ctx: ctx, a: a, b: b, factor: factor)
                } else {
                    drawLineMeasurement(ctx: ctx, a: a, b: b, factor: factor)
                }

                // Guide lines
                drawGuideLines(ctx: ctx, point: b)
            }

            // Point A marker
            drawPoint(ctx: ctx, point: a, label: "A")

            if let b = pointB {
                drawPoint(ctx: ctx, point: b, label: "B")
            }
        }

        // Info panel
        drawInfoPanel(ctx: ctx, factor: factor)
    }

    private func drawLineMeasurement(ctx: CGContext, a: CGPoint, b: CGPoint, factor: CGFloat) {
        // Dashed line
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemYellow.cgColor)
        ctx.setLineWidth(2)
        ctx.setLineDash(phase: 0, lengths: [6, 4])
        ctx.move(to: a)
        ctx.addLine(to: b)
        ctx.strokePath()
        ctx.restoreGState()

        // Distance label
        let dx = b.x - a.x
        let dy = b.y - a.y
        let distance = sqrt(dx * dx + dy * dy) * factor
        let unit = showInPoints ? "pt" : "px"
        let label = String(format: "%.1f %@", distance, unit)

        let midPoint = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 + 14)
        drawLabel(ctx: ctx, text: label, at: midPoint)
    }

    private func drawRectMeasurement(ctx: CGContext, a: CGPoint, b: CGPoint, factor: CGFloat) {
        let rect = CGRect(
            x: min(a.x, b.x), y: min(a.y, b.y),
            width: abs(b.x - a.x), height: abs(b.y - a.y)
        )

        // Dashed rectangle
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemYellow.cgColor)
        ctx.setLineWidth(2)
        ctx.setLineDash(phase: 0, lengths: [6, 4])
        ctx.stroke(rect)
        ctx.restoreGState()

        let unit = showInPoints ? "pt" : "px"
        let w = rect.width * factor
        let h = rect.height * factor

        // Width label (top center)
        let wLabel = String(format: "%.0f %@", w, unit)
        drawLabel(ctx: ctx, text: wLabel, at: CGPoint(x: rect.midX, y: rect.maxY + 14))

        // Height label (right center)
        let hLabel = String(format: "%.0f %@", h, unit)
        drawLabel(ctx: ctx, text: hLabel, at: CGPoint(x: rect.maxX + 8, y: rect.midY))

        // Dimensions label (center)
        let diagLabel = String(format: "%.0f\u{00D7}%.0f", w, h)
        drawLabel(ctx: ctx, text: diagLabel, at: CGPoint(x: rect.midX, y: rect.midY))
    }

    private func drawGuideLines(ctx: CGContext, point: CGPoint) {
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemYellow.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(0.5)
        ctx.setLineDash(phase: 0, lengths: [3, 3])

        // Horizontal guide
        ctx.move(to: CGPoint(x: bounds.minX, y: point.y))
        ctx.addLine(to: CGPoint(x: bounds.maxX, y: point.y))
        ctx.strokePath()

        // Vertical guide
        ctx.move(to: CGPoint(x: point.x, y: bounds.minY))
        ctx.addLine(to: CGPoint(x: point.x, y: bounds.maxY))
        ctx.strokePath()

        ctx.restoreGState()
    }

    private func drawPoint(ctx: CGContext, point: CGPoint, label: String) {
        // Cross marker
        let size: CGFloat = 6
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemYellow.cgColor)
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: point.x - size, y: point.y))
        ctx.addLine(to: CGPoint(x: point.x + size, y: point.y))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: point.x, y: point.y - size))
        ctx.addLine(to: CGPoint(x: point.x, y: point.y + size))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private func drawLabel(ctx: CGContext, text: String, at point: CGPoint) {
        let nsText = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        let size = nsText.size(withAttributes: attrs)
        let bgRect = CGRect(
            x: point.x - size.width / 2 - 4,
            y: point.y - size.height / 2 - 2,
            width: size.width + 8,
            height: size.height + 4
        )

        ctx.saveGState()
        let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.75).cgColor)
        ctx.addPath(bgPath)
        ctx.fillPath()
        ctx.restoreGState()

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        nsText.draw(at: NSPoint(x: bgRect.origin.x + 4, y: bgRect.origin.y + 2), withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawInfoPanel(ctx: CGContext, factor: CGFloat) {
        let unit = showInPoints ? "pt" : "px"
        var lines: [String] = ["Space: toggle \(unit)  |  ESC: exit"]

        if let a = pointA {
            lines.insert(String(format: "A: (%.0f, %.0f) %@", a.x * factor, a.y * factor, unit), at: 0)
            if let b = pointB {
                lines.insert(String(format: "B: (%.0f, %.0f) %@", b.x * factor, b.y * factor, unit), at: 1)
            }
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.white,
        ]

        let lineHeight: CGFloat = 16
        let panelHeight = CGFloat(lines.count) * lineHeight + 12
        let panelWidth: CGFloat = 250
        let panelRect = CGRect(x: bounds.maxX - panelWidth - 16, y: bounds.maxY - panelHeight - 16, width: panelWidth, height: panelHeight)

        ctx.saveGState()
        let bgPath = CGPath(roundedRect: panelRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.7).cgColor)
        ctx.addPath(bgPath)
        ctx.fillPath()
        ctx.restoreGState()

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        for (i, line) in lines.enumerated() {
            let y = panelRect.maxY - CGFloat(i + 1) * lineHeight - 2
            (line as NSString).draw(at: NSPoint(x: panelRect.minX + 8, y: y), withAttributes: attrs)
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}
