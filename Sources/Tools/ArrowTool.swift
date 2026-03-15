import AppKit

@MainActor
final class ArrowTool: DrawingTool {
    let toolType: DrawingToolType = .arrow
    var cursor: NSCursor { .crosshair }

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var color: NSColor = .systemRed
    private var strokeWidth: CGFloat = 3.0

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        startPoint = point
        currentPoint = point
        color = canvas.store.currentColor
        strokeWidth = canvas.store.currentStrokeWidth
    }

    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        if modifiers.contains(.shift), let start = startPoint {
            currentPoint = snapTo45Degrees(from: start, to: point)
        } else {
            currentPoint = point
        }
        canvas.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        guard let start = startPoint else { return }
        let end: CGPoint
        if modifiers.contains(.shift) {
            end = snapTo45Degrees(from: start, to: point)
        } else {
            end = point
        }

        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        if dx > 2 || dy > 2 {
            let annotation = ArrowAnnotation(
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

    func drawPreview(in ctx: CGContext, scale: CGFloat) {
        guard let start = startPoint, let current = currentPoint else { return }
        let preview = ArrowAnnotation(
            startPoint: start,
            endPoint: current,
            color: color,
            strokeWidth: strokeWidth
        )
        preview.draw(in: ctx, baseImage: nil)
    }

    func cancel() {
        startPoint = nil
        currentPoint = nil
    }

    // MARK: - Angle Snapping

    /// Snap the drag direction to the nearest 45-degree increment.
    private func snapTo45Degrees(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)
        let snapped = (angle / (.pi / 4)).rounded() * (.pi / 4)
        let distance = hypot(dx, dy)
        return CGPoint(
            x: start.x + distance * cos(snapped),
            y: start.y + distance * sin(snapped)
        )
    }
}
