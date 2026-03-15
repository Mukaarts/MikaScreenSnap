// LineTool.swift
// MikaScreenSnap
//
// Drawing tool for straight lines without arrowheads.
// Shift-drag constrains to 45-degree increments.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class LineTool: DrawingTool {
    let toolType: DrawingToolType = .line
    var cursor: NSCursor { .crosshair }

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var color: NSColor = .systemRed
    private var strokeWidth: CGFloat = 3.0

    // MARK: - Mouse Events

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        color = canvas.store.currentColor
        strokeWidth = canvas.store.currentStrokeWidth
        startPoint = point
        currentPoint = point
    }

    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        guard let start = startPoint else { return }
        currentPoint = modifiers.contains(.shift) ? constrainedEndPoint(from: start, to: point) : point
        canvas.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        guard let start = startPoint else { return }
        let end = modifiers.contains(.shift) ? constrainedEndPoint(from: start, to: point) : point

        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        if dx > 2 || dy > 2 {
            let annotation = LineAnnotation(
                startPoint: start,
                endPoint: end,
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
        guard let start = startPoint, let end = currentPoint else { return }

        let temp = LineAnnotation(
            startPoint: start,
            endPoint: end,
            color: color,
            strokeWidth: strokeWidth
        )
        temp.draw(in: ctx, baseImage: nil)
    }

    // MARK: - Cancel

    func cancel() {
        startPoint = nil
        currentPoint = nil
    }

    // MARK: - Shift-Snap to 45-Degree Increments

    private func constrainedEndPoint(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)

        // Snap to nearest 45-degree (pi/4) increment
        let snappedAngle = (angle / (.pi / 4)).rounded() * (.pi / 4)
        let length = sqrt(dx * dx + dy * dy)

        return CGPoint(
            x: start.x + length * cos(snappedAngle),
            y: start.y + length * sin(snappedAngle)
        )
    }
}
