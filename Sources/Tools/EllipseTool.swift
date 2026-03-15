import AppKit

@MainActor
final class EllipseTool: DrawingTool {
    let toolType: DrawingToolType = .ellipse
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
            currentPoint = constrainToCircle(from: start, to: point)
        } else {
            currentPoint = point
        }
        canvas.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        guard let start = startPoint else { return }
        let end: CGPoint
        if modifiers.contains(.shift) {
            end = constrainToCircle(from: start, to: point)
        } else {
            end = point
        }

        let rect = makeRect(from: start, to: end)
        if rect.width > 2 && rect.height > 2 {
            let annotation = EllipseAnnotation(
                rect: rect,
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
        let rect = makeRect(from: start, to: current)
        let preview = EllipseAnnotation(
            rect: rect,
            color: color,
            strokeWidth: strokeWidth
        )
        preview.draw(in: ctx, baseImage: nil)
    }

    func cancel() {
        startPoint = nil
        currentPoint = nil
    }

    // MARK: - Helpers

    /// Build a CGRect from two corner points.
    private func makeRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p1.x - p2.x),
            height: abs(p1.y - p2.y)
        )
    }

    /// Constrain the drag to produce a square bounding box (i.e., a circle).
    /// The side length equals the larger of the horizontal and vertical
    /// distances, and the sign of each axis is preserved so the circle
    /// extends in the drag direction.
    private func constrainToCircle(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let side = max(abs(dx), abs(dy))
        return CGPoint(
            x: start.x + copysign(side, dx),
            y: start.y + copysign(side, dy)
        )
    }
}
