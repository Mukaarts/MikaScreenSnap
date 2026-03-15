// FreehandTool.swift
// MikaScreenSnap
//
// Drawing tool for freehand/scribble annotations.
// Collects points during drag with 3px minimum distance between samples.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class FreehandTool: DrawingTool {
    let toolType: DrawingToolType = .freehand
    var cursor: NSCursor { .crosshair }

    private var points: [CGPoint] = []
    private var color: NSColor = .systemRed
    private var strokeWidth: CGFloat = 3.0

    // MARK: - Mouse Events

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        color = canvas.store.currentColor
        strokeWidth = canvas.store.currentStrokeWidth
        points = [point]
    }

    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        guard let last = points.last else { return }
        let dx = point.x - last.x
        let dy = point.y - last.y
        if dx * dx + dy * dy >= 9 { // 3px minimum distance
            points.append(point)
            canvas.needsDisplay = true
        }
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        if points.count > 2 {
            let annotation = FreehandAnnotation(
                points: points,
                color: color,
                strokeWidth: strokeWidth
            )
            canvas.store.addAnnotation(annotation)
        }
        cancel()
        canvas.needsDisplay = true
    }

    // MARK: - Preview

    func drawPreview(in ctx: CGContext, scale: CGFloat) {
        guard points.count >= 2 else { return }

        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        ctx.move(to: points[0])
        for i in 1..<points.count {
            ctx.addLine(to: points[i])
        }
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: - Cancel

    func cancel() {
        points.removeAll()
    }
}
