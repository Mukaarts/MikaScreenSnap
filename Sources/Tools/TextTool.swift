// TextTool.swift
// MikaScreenSnap
//
// Drawing tool for placing editable text annotations.
// On click, places an NSTextField at the view-space position.
// The canvas calls back when text editing is finalized.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class TextTool: DrawingTool {
    let toolType: DrawingToolType = .text
    var cursor: NSCursor { .iBeam }

    private var clickPoint: CGPoint?
    private var color: NSColor = .systemRed

    // MARK: - Mouse Events

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        // Finalize any existing text field first
        canvas.finalizeActiveTextField()

        color = canvas.store.currentColor
        clickPoint = point
        canvas.placeTextField(at: point, color: color)
    }

    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        // no-op for text
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        // no-op for text
    }

    // MARK: - Preview

    func drawPreview(in ctx: CGContext, scale: CGFloat) {
        // no-op — text field is a real NSView
    }

    // MARK: - Text Finalization

    /// Called by the canvas when the text field editing ends.
    func finalizeText(_ text: String, canvas: AnnotationCanvasView) {
        guard let point = clickPoint, !text.isEmpty else {
            cancel()
            return
        }

        let pixelScale = canvas.imagePixelScale
        let fontSize = 16.0 * pixelScale
        let annotation = TextAnnotation(
            position: point,
            text: text,
            font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            color: color
        )
        canvas.store.addAnnotation(annotation)
        cancel()
    }

    // MARK: - Cancel

    func cancel() {
        clickPoint = nil
    }
}
