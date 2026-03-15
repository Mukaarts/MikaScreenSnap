import AppKit

@MainActor
final class HighlightTool: DrawingTool {
    let toolType: DrawingToolType = .highlight
    var cursor: NSCursor { .crosshair }

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        startPoint = point
        currentPoint = point
    }

    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        currentPoint = point
        canvas.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        guard let start = startPoint else { return }
        let rect = makeRect(from: start, to: point)
        if rect.width > 2 && rect.height > 2 {
            let annotation = HighlightAnnotation(rect: rect)
            canvas.store.addAnnotation(annotation)
        }
        cancel()
        canvas.needsDisplay = true
    }

    func drawPreview(in ctx: CGContext, scale: CGFloat) {
        guard let start = startPoint, let current = currentPoint else { return }
        let rect = makeRect(from: start, to: current)
        ctx.saveGState()
        ctx.setFillColor(NSColor.yellow.withAlphaComponent(0.3).cgColor)
        ctx.fill(rect)
        ctx.restoreGState()
    }

    func cancel() {
        startPoint = nil
        currentPoint = nil
    }

    private func makeRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        CGRect(x: min(p1.x, p2.x), y: min(p1.y, p2.y),
               width: abs(p1.x - p2.x), height: abs(p1.y - p2.y))
    }
}
