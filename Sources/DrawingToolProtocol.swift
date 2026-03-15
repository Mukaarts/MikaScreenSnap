import AppKit

@MainActor
protocol DrawingTool: AnyObject {
    var toolType: DrawingToolType { get }
    var cursor: NSCursor { get }
    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView)
    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView)
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView)
    func keyDown(event: NSEvent, canvas: AnnotationCanvasView) -> Bool
    func drawPreview(in ctx: CGContext, scale: CGFloat)
    func cancel()
}

extension DrawingTool {
    func keyDown(event: NSEvent, canvas: AnnotationCanvasView) -> Bool {
        return false
    }

    func cancel() {}
}
