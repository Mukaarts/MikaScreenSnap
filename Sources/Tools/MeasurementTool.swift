// MeasurementTool.swift
// MikaScreenSnap
//
// Non-destructive measurement tool for the annotation editor.
// Draws measurements only in preview (not exported).
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class MeasurementTool: DrawingTool {
    let toolType: DrawingToolType = .measure
    var cursor: NSCursor { .crosshair }

    private var pointA: CGPoint?
    private var pointB: CGPoint?
    private var isDragging = false
    private var showInPoints = false

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        if pointA == nil || pointB != nil {
            // Start new measurement
            pointA = point
            pointB = nil
            isDragging = true
        } else {
            // Set second point
            pointB = point
            isDragging = false
        }
        canvas.needsDisplay = true
    }

    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        pointB = point
        canvas.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        if isDragging {
            if let a = pointA {
                let dx = abs(point.x - a.x)
                let dy = abs(point.y - a.y)
                if dx > 2 || dy > 2 {
                    pointB = point
                }
            }
            isDragging = false
        }
        canvas.needsDisplay = true
    }

    func keyDown(event: NSEvent, canvas: AnnotationCanvasView) -> Bool {
        if event.keyCode == 49 { // Space toggles px/pt
            showInPoints.toggle()
            canvas.needsDisplay = true
            return true
        }
        return false
    }

    func drawPreview(in ctx: CGContext, scale: CGFloat) {
        guard let a = pointA else { return }
        let b = pointB ?? a

        let pixelScale = 1.0 / scale
        let factor = showInPoints ? 1.0 : 1.0 // In editor, measurements are in image pixels

        let dx = abs(b.x - a.x)
        let dy = abs(b.y - a.y)

        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemYellow.cgColor)
        ctx.setLineWidth(2 * pixelScale)
        ctx.setLineDash(phase: 0, lengths: [6 * pixelScale, 4 * pixelScale])

        if dx > 3 * pixelScale && dy > 3 * pixelScale {
            // Rectangle mode
            let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: dx, height: dy)
            ctx.stroke(rect)
            ctx.restoreGState()

            let unit = showInPoints ? "pt" : "px"
            let wLabel = String(format: "%.0f %@", dx * factor, unit)
            let hLabel = String(format: "%.0f %@", dy * factor, unit)
            let dimLabel = String(format: "%.0f\u{00D7}%.0f", dx * factor, dy * factor)

            drawMeasureLabel(ctx: ctx, text: wLabel, at: CGPoint(x: rect.midX, y: rect.maxY + 14 * pixelScale), pixelScale: pixelScale)
            drawMeasureLabel(ctx: ctx, text: hLabel, at: CGPoint(x: rect.maxX + 10 * pixelScale, y: rect.midY), pixelScale: pixelScale)
            drawMeasureLabel(ctx: ctx, text: dimLabel, at: CGPoint(x: rect.midX, y: rect.midY), pixelScale: pixelScale)
        } else {
            // Line mode
            ctx.move(to: a)
            ctx.addLine(to: b)
            ctx.strokePath()
            ctx.restoreGState()

            let distance = sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)) * factor
            let unit = showInPoints ? "pt" : "px"
            let label = String(format: "%.1f %@", distance, unit)
            let midPoint = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 + 14 * pixelScale)
            drawMeasureLabel(ctx: ctx, text: label, at: midPoint, pixelScale: pixelScale)
        }

        // Draw point markers
        drawMarker(ctx: ctx, at: a, pixelScale: pixelScale)
        if pointB != nil {
            drawMarker(ctx: ctx, at: b, pixelScale: pixelScale)
        }
    }

    func cancel() {
        pointA = nil
        pointB = nil
        isDragging = false
    }

    private func drawMarker(ctx: CGContext, at point: CGPoint, pixelScale: CGFloat) {
        let size: CGFloat = 5 * pixelScale
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemYellow.cgColor)
        ctx.setLineWidth(2 * pixelScale)
        ctx.move(to: CGPoint(x: point.x - size, y: point.y))
        ctx.addLine(to: CGPoint(x: point.x + size, y: point.y))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: point.x, y: point.y - size))
        ctx.addLine(to: CGPoint(x: point.x, y: point.y + size))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private func drawMeasureLabel(ctx: CGContext, text: String, at point: CGPoint, pixelScale: CGFloat) {
        let nsText = text as NSString
        let fontSize: CGFloat = 12 * pixelScale
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        let size = nsText.size(withAttributes: attrs)
        let padding: CGFloat = 4 * pixelScale
        let bgRect = CGRect(
            x: point.x - size.width / 2 - padding,
            y: point.y - size.height / 2 - padding / 2,
            width: size.width + padding * 2,
            height: size.height + padding
        )

        ctx.saveGState()
        let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 4 * pixelScale, cornerHeight: 4 * pixelScale, transform: nil)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.75).cgColor)
        ctx.addPath(bgPath)
        ctx.fillPath()
        ctx.restoreGState()

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        nsText.draw(at: NSPoint(x: bgRect.origin.x + padding, y: bgRect.origin.y + padding / 2), withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
    }
}
