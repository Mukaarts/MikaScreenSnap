import AppKit
import CoreImage

@MainActor
final class AnnotationCanvasView: NSView {
    let baseImage: NSImage
    let store: AnnotationStore

    // Tools
    private var tools: [DrawingToolType: any DrawingTool] = [:]
    var currentTool: (any DrawingTool)? { tools[store.selectedTool] }
    var selectionTool: SelectionTool? { tools[.select] as? SelectionTool }

    // Text editing
    private var activeTextField: NSTextField?
    private var activeTextImagePoint: CGPoint?

    // Pan state
    private var isPanning: Bool = false
    private var panStartPoint: CGPoint?
    private var spaceDown: Bool = false

    // Local event monitor for space bar (since flagsChanged does not detect it)
    // nonisolated(unsafe) so deinit can remove the monitor
    private nonisolated(unsafe) var localKeyMonitor: Any?

    init(baseImage: NSImage, store: AnnotationStore) {
        self.baseImage = baseImage
        self.store = store
        super.init(frame: .zero)
        setupTools()
        installSpaceBarMonitor()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    // OCR selection mode
    var isOCRSelectionMode: Bool = false
    private var ocrSelectionStart: CGPoint?
    private var ocrSelectionCurrent: CGPoint?
    var onOCRSelection: ((CGRect) -> Void)?

    private func setupTools() {
        tools[.select] = SelectionTool()
        tools[.arrow] = ArrowTool()
        tools[.rectangle] = RectangleTool()
        tools[.ellipse] = EllipseTool()
        tools[.line] = LineTool()
        tools[.freehand] = FreehandTool()
        tools[.text] = TextTool()
        tools[.highlight] = HighlightTool()
        tools[.blur] = BlurTool()
        tools[.pixelate] = PixelateTool()
        tools[.measure] = MeasurementTool()
    }

    /// Install a local event monitor that tracks space bar press/release for pan mode.
    /// `flagsChanged` only fires for modifier keys, so we use a local monitor for keyDown/keyUp
    /// to detect the space bar (keyCode 49).
    private func installSpaceBarMonitor() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 49 { // space bar
                let isDown = event.type == .keyDown
                if self.spaceDown != isDown {
                    self.spaceDown = isDown
                    if !isDown && self.isPanning {
                        self.isPanning = false
                        self.panStartPoint = nil
                    }
                    self.window?.invalidateCursorRects(for: self)
                }
                // Consume the event when we are the first responder to prevent beep
                if self.window?.firstResponder === self {
                    return nil
                }
            }
            return event
        }
    }

    // MARK: - Image Size

    var imagePixelSize: CGSize {
        guard let cg = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return baseImage.size
        }
        return CGSize(width: cg.width, height: cg.height)
    }

    var imagePixelScale: CGFloat {
        guard let cg = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 1 }
        return CGFloat(cg.width) / baseImage.size.width
    }

    // MARK: - Coordinate Transforms

    /// The affine transform from image pixel space to view space.
    /// Incorporates: fit-to-view scaling, zoom, and pan offset.
    private var imageToViewTransform: CGAffineTransform {
        let imgSize = imagePixelSize
        guard imgSize.width > 0, imgSize.height > 0, bounds.width > 0, bounds.height > 0 else {
            return .identity
        }
        let fitScale = min(bounds.width / imgSize.width, bounds.height / imgSize.height)
        let effectiveScale = fitScale * store.zoomLevel

        return CGAffineTransform.identity
            .translatedBy(x: bounds.midX + store.panOffset.x, y: bounds.midY + store.panOffset.y)
            .scaledBy(x: effectiveScale, y: effectiveScale)
            .translatedBy(x: -imgSize.width / 2, y: -imgSize.height / 2)
    }

    private var viewToImageTransform: CGAffineTransform {
        imageToViewTransform.inverted()
    }

    /// Convert view coordinate to image pixel coordinate.
    func viewToImage(_ point: CGPoint) -> CGPoint {
        point.applying(viewToImageTransform)
    }

    /// Convert image pixel coordinate to view coordinate.
    func imageToView(_ point: CGPoint) -> CGPoint {
        point.applying(imageToViewTransform)
    }

    /// The rect in view space where the image is displayed.
    var imageViewRect: CGRect {
        let imgSize = imagePixelSize
        let imageRect = CGRect(origin: .zero, size: imgSize)
        return imageRect.applying(imageToViewTransform)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // 1. Background
        ctx.setFillColor(NSColor.windowBackgroundColor.cgColor)
        ctx.fill(bounds)

        // Draw checkerboard in image area to indicate transparency
        drawCheckerboard(ctx: ctx)

        // 2. Everything else is drawn in image pixel space via the transform
        guard let cgBase = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let imgSize = imagePixelSize

        ctx.saveGState()
        ctx.concatenate(imageToViewTransform)

        // 2a. Base image
        ctx.draw(cgBase, in: CGRect(origin: .zero, size: imgSize))

        // 2b. Committed annotations (sorted by z-order)
        let sorted = store.annotations.sorted { $0.zIndex < $1.zIndex }
        for annotation in sorted {
            annotation.draw(in: ctx, baseImage: cgBase)
        }

        // 2c. Selection handles
        if let selected = store.selectedAnnotation, store.selectedTool == .select {
            selectionTool?.drawSelectionHandles(in: ctx, bounds: selected.bounds)
        }

        // 2d. Tool preview (in image pixel space)
        let fitScale = min(bounds.width / imgSize.width, bounds.height / imgSize.height)
        currentTool?.drawPreview(in: ctx, scale: fitScale * store.zoomLevel)

        // 2e. OCR selection rectangle
        if isOCRSelectionMode, let start = ocrSelectionStart, let current = ocrSelectionCurrent {
            let selRect = CGRect(
                x: min(start.x, current.x), y: min(start.y, current.y),
                width: abs(current.x - start.x), height: abs(current.y - start.y)
            )
            ctx.saveGState()
            ctx.setStrokeColor(NSColor.systemBlue.cgColor)
            ctx.setLineWidth(2 / (fitScale * store.zoomLevel))
            ctx.setLineDash(phase: 0, lengths: [6 / (fitScale * store.zoomLevel), 4 / (fitScale * store.zoomLevel)])
            ctx.stroke(selRect)
            ctx.setFillColor(NSColor.systemBlue.withAlphaComponent(0.1).cgColor)
            ctx.fill(selRect)
            ctx.restoreGState()
        }

        ctx.restoreGState()
    }

    private func drawCheckerboard(ctx: CGContext) {
        let viewRect = imageViewRect
        guard viewRect.width > 0 && viewRect.height > 0 else { return }

        let checkSize: CGFloat = 8
        ctx.saveGState()
        ctx.clip(to: viewRect)

        let cols = Int(ceil(viewRect.width / checkSize))
        let rows = Int(ceil(viewRect.height / checkSize))

        for row in 0..<rows {
            for col in 0..<cols {
                let isLight = (row + col) % 2 == 0
                ctx.setFillColor(isLight ? NSColor.white.cgColor : NSColor(white: 0.85, alpha: 1).cgColor)
                let rect = CGRect(
                    x: viewRect.minX + CGFloat(col) * checkSize,
                    y: viewRect.minY + CGFloat(row) * checkSize,
                    width: checkSize, height: checkSize
                )
                ctx.fill(rect)
            }
        }
        ctx.restoreGState()
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)

        if spaceDown {
            isPanning = true
            panStartPoint = viewPoint
            return
        }

        let imagePoint = viewToImage(viewPoint)

        // OCR selection mode
        if isOCRSelectionMode {
            ocrSelectionStart = imagePoint
            ocrSelectionCurrent = imagePoint
            needsDisplay = true
            return
        }

        // Finalize text field if clicking elsewhere while a non-text tool is active
        if activeTextField != nil && !(currentTool is TextTool) {
            finalizeActiveTextField()
        }

        currentTool?.mouseDown(at: imagePoint, modifiers: event.modifierFlags, canvas: self)
    }

    override func mouseDragged(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)

        if isPanning, let panStart = panStartPoint {
            let dx = viewPoint.x - panStart.x
            let dy = viewPoint.y - panStart.y
            store.panOffset.x += dx
            store.panOffset.y += dy
            panStartPoint = viewPoint
            needsDisplay = true
            return
        }

        let imagePoint = viewToImage(viewPoint)

        if isOCRSelectionMode {
            ocrSelectionCurrent = imagePoint
            needsDisplay = true
            return
        }

        currentTool?.mouseDragged(to: imagePoint, modifiers: event.modifierFlags, canvas: self)
    }

    override func mouseUp(with event: NSEvent) {
        if isPanning {
            isPanning = false
            panStartPoint = nil
            return
        }

        let viewPoint = convert(event.locationInWindow, from: nil)
        let imagePoint = viewToImage(viewPoint)

        if isOCRSelectionMode, let start = ocrSelectionStart {
            let rect = CGRect(
                x: min(start.x, imagePoint.x),
                y: min(start.y, imagePoint.y),
                width: abs(imagePoint.x - start.x),
                height: abs(imagePoint.y - start.y)
            )
            if rect.width > 3 && rect.height > 3 {
                isOCRSelectionMode = false
                ocrSelectionStart = nil
                ocrSelectionCurrent = nil
                needsDisplay = true
                onOCRSelection?(rect)
            }
            return
        }

        currentTool?.mouseUp(at: imagePoint, modifiers: event.modifierFlags, canvas: self)
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        // Let current tool handle first
        if currentTool?.keyDown(event: event, canvas: self) == true {
            return
        }

        // ESC
        if event.keyCode == 53 {
            currentTool?.cancel()
            finalizeActiveTextField()
            needsDisplay = true
            return
        }

        super.keyDown(with: event)
    }

    // MARK: - Zoom

    func zoomIn() {
        store.zoomLevel = min(store.zoomLevel * 1.25, 10.0)
        needsDisplay = true
    }

    func zoomOut() {
        store.zoomLevel = max(store.zoomLevel / 1.25, 0.1)
        needsDisplay = true
    }

    func zoomToFit() {
        store.zoomLevel = 1.0
        store.panOffset = .zero
        needsDisplay = true
    }

    override func magnify(with event: NSEvent) {
        let newZoom = store.zoomLevel * (1 + event.magnification)
        store.zoomLevel = min(max(newZoom, 0.1), 10.0)
        needsDisplay = true
    }

    // MARK: - Text Field Support (for TextTool)

    /// Place a text field at the given image-pixel position with the specified color.
    /// Called by TextTool to create an editable text field on the canvas.
    func placeTextField(at imagePoint: CGPoint, color: NSColor) {
        finalizeActiveTextField()

        let viewPoint = imageToView(imagePoint)
        let field = NSTextField(frame: NSRect(x: viewPoint.x, y: viewPoint.y - 12, width: 200, height: 24))
        field.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        field.textColor = color
        field.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        field.isBordered = false
        field.isBezeled = false
        field.isEditable = true
        field.isSelectable = true
        field.focusRingType = .none
        field.placeholderString = "Type here..."
        field.delegate = self
        field.target = self
        field.action = #selector(textFieldAction(_:))

        addSubview(field)
        window?.makeFirstResponder(field)

        activeTextField = field
        activeTextImagePoint = imagePoint
    }

    @objc private func textFieldAction(_ sender: NSTextField) {
        finalizeActiveTextField()
    }

    /// Finalize the currently active text field, if any.
    /// Called by TextTool or internally when editing ends.
    func finalizeActiveTextField() {
        guard let field = activeTextField else { return }
        let text = field.stringValue
        field.removeFromSuperview()
        activeTextField = nil

        if let textTool = currentTool as? TextTool {
            textTool.finalizeText(text, canvas: self)
        }
        activeTextImagePoint = nil

        window?.makeFirstResponder(self)
    }

    // MARK: - Tool Changed

    func toolChanged() {
        currentTool?.cancel()
        finalizeActiveTextField()
        window?.invalidateCursorRects(for: self)
        needsDisplay = true
    }

    // MARK: - Cursor

    override func resetCursorRects() {
        if spaceDown {
            addCursorRect(bounds, cursor: isPanning ? .closedHand : .openHand)
        } else if let tool = currentTool {
            addCursorRect(bounds, cursor: tool.cursor)
        } else {
            addCursorRect(bounds, cursor: .crosshair)
        }
    }
}

// MARK: - NSTextFieldDelegate

extension AnnotationCanvasView: NSTextFieldDelegate {
    nonisolated func controlTextDidEndEditing(_ obj: Notification) {
        MainActor.assumeIsolated {
            finalizeActiveTextField()
        }
    }
}
