import AppKit

enum HandlePosition: CaseIterable {
    case topLeft, topCenter, topRight
    case middleLeft, middleRight
    case bottomLeft, bottomCenter, bottomRight
}

@MainActor
final class SelectionTool: DrawingTool {
    let toolType: DrawingToolType = .select
    var cursor: NSCursor { .arrow }

    private let handleSize: CGFloat = 8
    private var dragMode: DragMode = .none
    private var dragStart: CGPoint?
    private var preDragSnapshot: [AnnotationSnapshot]?
    private var activeHandle: HandlePosition?

    private enum DragMode {
        case none, moving, resizing
    }

    // MARK: - Mouse Events

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        let store = canvas.store

        // Check if clicking on a resize handle of the already-selected annotation
        if let selected = store.selectedAnnotation {
            if let handle = hitTestHandle(point: point, bounds: selected.bounds) {
                dragMode = .resizing
                dragStart = point
                activeHandle = handle
                preDragSnapshot = store.snapshotAnnotations()
                return
            }
        }

        // Hit-test annotations (topmost first) and select
        store.selectAnnotation(at: point)

        if let selected = store.selectedAnnotation, selected.contains(point) {
            dragMode = .moving
            dragStart = point
            preDragSnapshot = store.snapshotAnnotations()
        } else {
            dragMode = .none
        }

        canvas.needsDisplay = true
    }

    func mouseDragged(to point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        guard let start = dragStart, let selected = canvas.store.selectedAnnotation else { return }

        switch dragMode {
        case .moving:
            let dx = point.x - start.x
            let dy = point.y - start.y
            selected.moved(by: CGSize(width: dx, height: dy))
            dragStart = point
            canvas.needsDisplay = true

        case .resizing:
            guard let handle = activeHandle else { return }
            let currentBounds = selected.bounds
            let newBounds = computeResizedBounds(
                original: currentBounds, handle: handle,
                currentPoint: point, startPoint: start
            )
            selected.resized(from: currentBounds, to: newBounds)
            dragStart = point
            canvas.needsDisplay = true

        case .none:
            break
        }
    }

    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, canvas: AnnotationCanvasView) {
        if dragMode == .moving || dragMode == .resizing {
            // Register a single undo for the entire drag operation using the
            // snapshot captured at mouseDown.
            if let snapshot = preDragSnapshot {
                canvas.store.registerUndoFromSnapshot(snapshot)
            }
            canvas.store.hasUnsavedChanges = true
        }

        dragMode = .none
        dragStart = nil
        preDragSnapshot = nil
        activeHandle = nil
    }

    func keyDown(event: NSEvent, canvas: AnnotationCanvasView) -> Bool {
        // Delete (backspace = 51, forward-delete = 117)
        if event.keyCode == 51 || event.keyCode == 117 {
            canvas.store.deleteSelected()
            canvas.needsDisplay = true
            return true
        }
        return false
    }

    func drawPreview(in ctx: CGContext, scale: CGFloat) {
        // Selection handles are drawn by the canvas via drawSelectionHandles(_:bounds:),
        // not through the standard tool preview path.
    }

    func cancel() {
        dragMode = .none
        dragStart = nil
        preDragSnapshot = nil
        activeHandle = nil
    }

    // MARK: - Handle Hit Testing

    func hitTestHandle(point: CGPoint, bounds: CGRect) -> HandlePosition? {
        for handle in HandlePosition.allCases {
            let center = handleCenter(for: handle, in: bounds)
            let handleRect = CGRect(
                x: center.x - handleSize / 2,
                y: center.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            // Expand hit area slightly for easier grabbing
            if handleRect.insetBy(dx: -4, dy: -4).contains(point) {
                return handle
            }
        }
        return nil
    }

    func handleCenter(for position: HandlePosition, in bounds: CGRect) -> CGPoint {
        switch position {
        case .topLeft:      return CGPoint(x: bounds.minX, y: bounds.maxY)
        case .topCenter:    return CGPoint(x: bounds.midX, y: bounds.maxY)
        case .topRight:     return CGPoint(x: bounds.maxX, y: bounds.maxY)
        case .middleLeft:   return CGPoint(x: bounds.minX, y: bounds.midY)
        case .middleRight:  return CGPoint(x: bounds.maxX, y: bounds.midY)
        case .bottomLeft:   return CGPoint(x: bounds.minX, y: bounds.minY)
        case .bottomCenter: return CGPoint(x: bounds.midX, y: bounds.minY)
        case .bottomRight:  return CGPoint(x: bounds.maxX, y: bounds.minY)
        }
    }

    // MARK: - Resize Calculation

    private func computeResizedBounds(
        original: CGRect,
        handle: HandlePosition,
        currentPoint: CGPoint,
        startPoint: CGPoint
    ) -> CGRect {
        let dx = currentPoint.x - startPoint.x
        let dy = currentPoint.y - startPoint.y
        var r = original

        switch handle {
        case .topLeft:
            r.origin.x += dx
            r.size.width -= dx
            r.size.height += dy
        case .topCenter:
            r.size.height += dy
        case .topRight:
            r.size.width += dx
            r.size.height += dy
        case .middleLeft:
            r.origin.x += dx
            r.size.width -= dx
        case .middleRight:
            r.size.width += dx
        case .bottomLeft:
            r.origin.x += dx
            r.size.width -= dx
            r.origin.y += dy
            r.size.height -= dy
        case .bottomCenter:
            r.origin.y += dy
            r.size.height -= dy
        case .bottomRight:
            r.size.width += dx
            r.origin.y += dy
            r.size.height -= dy
        }

        // Enforce minimum size
        if r.width < 10 { r.size.width = 10 }
        if r.height < 10 { r.size.height = 10 }

        return r
    }

    // MARK: - Draw Selection Handles

    /// Draw a dashed selection border and resize handles around the given bounds.
    /// Called by the canvas when an annotation is selected.
    func drawSelectionHandles(in ctx: CGContext, bounds: CGRect) {
        // Dashed blue border
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemBlue.cgColor)
        ctx.setLineWidth(1.0)
        ctx.setLineDash(phase: 0, lengths: [4, 4])
        ctx.stroke(bounds)
        ctx.restoreGState()

        // Blue filled handle squares with white outline
        ctx.saveGState()
        ctx.setFillColor(NSColor.systemBlue.cgColor)
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.setLineWidth(1.0)

        for handle in HandlePosition.allCases {
            let center = handleCenter(for: handle, in: bounds)
            let rect = CGRect(
                x: center.x - handleSize / 2,
                y: center.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            ctx.fill(rect)
            ctx.stroke(rect)
        }
        ctx.restoreGState()
    }
}
