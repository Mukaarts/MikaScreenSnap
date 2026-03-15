import AppKit
import CoreImage

@MainActor
final class AnnotationCanvasView: NSView {
    let baseImage: NSImage
    let document: AnnotationDocument

    private var dragStartPoint: CGPoint?  // in image coordinates
    private var dragCurrentPoint: CGPoint?  // in image coordinates
    private var activeTextField: NSTextField?
    private var activeTextPosition: CGPoint?  // in image coordinates

    init(baseImage: NSImage, document: AnnotationDocument) {
        self.baseImage = baseImage
        self.document = document
        super.init(frame: .zero)

        document.onChange = { [weak self] in
            self?.needsDisplay = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    // MARK: - Coordinate Transforms

    /// The rect within this view where the image is drawn (aspect-fit).
    private var imageDrawRect: CGRect {
        let viewSize = bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }

        let imageSize = baseImage.size
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledW = imageSize.width * scale
        let scaledH = imageSize.height * scale
        let x = (viewSize.width - scaledW) / 2
        let y = (viewSize.height - scaledH) / 2
        return CGRect(x: x, y: y, width: scaledW, height: scaledH)
    }

    /// The scale factor from image points to CGImage pixels.
    private var imagePixelScale: CGFloat {
        guard let cg = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 1 }
        return CGFloat(cg.width) / baseImage.size.width
    }

    /// Convert view coordinate to image pixel coordinate.
    private func viewToImage(_ point: CGPoint) -> CGPoint {
        let drawRect = imageDrawRect
        guard drawRect.width > 0, drawRect.height > 0 else { return point }

        let viewScale = baseImage.size.width / drawRect.width
        let pixelScale = imagePixelScale

        let imgX = (point.x - drawRect.origin.x) * viewScale * pixelScale
        let imgY = (point.y - drawRect.origin.y) * viewScale * pixelScale
        return CGPoint(x: imgX, y: imgY)
    }

    /// Convert image pixel coordinate to view coordinate.
    private func imageToView(_ point: CGPoint) -> CGPoint {
        let drawRect = imageDrawRect
        guard baseImage.size.width > 0, baseImage.size.height > 0 else { return point }

        let pixelScale = imagePixelScale
        let viewScale = drawRect.width / (baseImage.size.width * pixelScale)

        let vx = point.x * viewScale + drawRect.origin.x
        let vy = point.y * viewScale + drawRect.origin.y
        return CGPoint(x: vx, y: vy)
    }

    /// Convert image pixel rect to view rect.
    private func imageRectToView(_ rect: CGRect) -> CGRect {
        let origin = imageToView(rect.origin)
        let corner = imageToView(CGPoint(x: rect.maxX, y: rect.maxY))
        return CGRect(
            x: min(origin.x, corner.x),
            y: min(origin.y, corner.y),
            width: abs(corner.x - origin.x),
            height: abs(corner.y - origin.y)
        )
    }

    /// Scale factor from image pixels to view points (for line widths, font sizes, etc).
    private var imageToViewScale: CGFloat {
        let drawRect = imageDrawRect
        let pixelScale = imagePixelScale
        guard baseImage.size.width > 0 else { return 1 }
        return drawRect.width / (baseImage.size.width * pixelScale)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Background
        ctx.setFillColor(NSColor.windowBackgroundColor.cgColor)
        ctx.fill(bounds)

        // Draw base image
        let drawRect = imageDrawRect
        baseImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)

        // Draw annotations in view space
        let scale = imageToViewScale
        guard let cgBase = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        for item in document.annotations {
            drawAnnotationInView(ctx: ctx, item: item, scale: scale, baseImage: cgBase)
        }

        // Draw in-progress annotation
        drawInProgressAnnotation(ctx: ctx, scale: scale, baseImage: cgBase)
    }

    private func drawAnnotationInView(ctx: CGContext, item: AnnotationItem, scale: CGFloat, baseImage: CGImage) {
        switch item.kind {
        case .arrow(let a):
            let viewStart = imageToView(a.startPoint)
            let viewEnd = imageToView(a.endPoint)
            let viewAnnotation = ArrowAnnotation(startPoint: viewStart, endPoint: viewEnd, color: a.color, lineWidth: a.lineWidth * scale)
            AnnotationRenderer.drawArrow(in: ctx, annotation: viewAnnotation)

        case .rectangle(let r):
            let viewRect = imageRectToView(r.rect)
            let viewAnnotation = RectAnnotation(rect: viewRect, color: r.color, lineWidth: r.lineWidth * scale)
            AnnotationRenderer.drawRectangle(in: ctx, annotation: viewAnnotation)

        case .text(let t):
            let viewPos = imageToView(t.position)
            let scaledFontSize = t.font.pointSize * scale
            let scaledFont = NSFont.systemFont(ofSize: max(scaledFontSize, 8), weight: .bold)
            let viewAnnotation = TextAnnotation(position: viewPos, text: t.text, font: scaledFont, color: t.color)
            AnnotationRenderer.drawText(in: ctx, annotation: viewAnnotation, imageHeight: bounds.height)

        case .blur(let b):
            let viewRect = imageRectToView(b.rect)
            // For view display: pixelate by drawing a small scaled version
            drawBlurInView(ctx: ctx, rect: viewRect, baseImage: baseImage, imageRect: b.rect, radius: b.radius * scale)
        }
    }

    private func drawBlurInView(ctx: CGContext, rect: CGRect, baseImage: CGImage, imageRect: CGRect, radius: CGFloat) {
        guard rect.width > 1 && rect.height > 1 else { return }

        // Clamp to base image bounds
        let imageBounds = CGRect(x: 0, y: 0, width: baseImage.width, height: baseImage.height)
        let clampedImageRect = imageRect.intersection(imageBounds)
        guard !clampedImageRect.isNull else { return }

        guard let cropped = baseImage.cropping(to: clampedImageRect) else { return }

        let ciImage = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        let ciContext = CIContext()
        guard let output = filter.outputImage,
              let blurred = ciContext.createCGImage(output, from: ciImage.extent) else { return }

        ctx.saveGState()
        ctx.clip(to: rect)
        ctx.draw(blurred, in: rect)
        ctx.restoreGState()
    }

    private func drawInProgressAnnotation(ctx: CGContext, scale: CGFloat, baseImage: CGImage) {
        guard let start = dragStartPoint, let current = dragCurrentPoint else { return }

        let viewStart = imageToView(start)
        let viewCurrent = imageToView(current)

        switch document.selectedTool {
        case .arrow:
            let a = ArrowAnnotation(startPoint: viewStart, endPoint: viewCurrent, color: document.currentColor, lineWidth: document.currentLineWidth * scale)
            AnnotationRenderer.drawArrow(in: ctx, annotation: a)

        case .rectangle:
            let rect = makeRect(from: viewStart, to: viewCurrent)
            let r = RectAnnotation(rect: rect, color: document.currentColor, lineWidth: document.currentLineWidth * scale)
            AnnotationRenderer.drawRectangle(in: ctx, annotation: r)

        case .blur:
            let viewRect = makeRect(from: viewStart, to: viewCurrent)
            // Dashed preview
            ctx.saveGState()
            ctx.setStrokeColor(NSColor.white.cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineDash(phase: 0, lengths: [6, 4])
            ctx.stroke(viewRect)
            ctx.restoreGState()

        case .text:
            break
        }
    }

    private func makeRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p1.x - p2.x),
            height: abs(p1.y - p2.y)
        )
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let imagePoint = viewToImage(viewPoint)

        // Finalize any active text field first
        finalizeTextField()

        if document.selectedTool == .text {
            placeTextField(at: viewPoint, imagePoint: imagePoint)
            return
        }

        dragStartPoint = imagePoint
        dragCurrentPoint = imagePoint
    }

    override func mouseDragged(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        dragCurrentPoint = viewToImage(viewPoint)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = dragStartPoint, dragCurrentPoint != nil else { return }

        let end = viewToImage(convert(event.locationInWindow, from: nil))

        switch document.selectedTool {
        case .arrow:
            let dx = abs(end.x - start.x)
            let dy = abs(end.y - start.y)
            if dx > 2 || dy > 2 {
                let annotation = AnnotationItem(kind: .arrow(ArrowAnnotation(
                    startPoint: start, endPoint: end,
                    color: document.currentColor, lineWidth: document.currentLineWidth
                )))
                document.addAnnotation(annotation)
            }

        case .rectangle:
            let rect = makeRect(from: start, to: end)
            if rect.width > 2 && rect.height > 2 {
                let annotation = AnnotationItem(kind: .rectangle(RectAnnotation(
                    rect: rect, color: document.currentColor, lineWidth: document.currentLineWidth
                )))
                document.addAnnotation(annotation)
            }

        case .blur:
            let rect = makeRect(from: start, to: end)
            if rect.width > 2 && rect.height > 2 {
                let annotation = AnnotationItem(kind: .blur(BlurAnnotation(rect: rect)))
                document.addAnnotation(annotation)
            }

        case .text:
            break
        }

        dragStartPoint = nil
        dragCurrentPoint = nil
        needsDisplay = true
    }

    // MARK: - Text Tool

    private func placeTextField(at viewPoint: CGPoint, imagePoint: CGPoint) {
        let field = NSTextField(frame: NSRect(x: viewPoint.x, y: viewPoint.y - 12, width: 200, height: 24))
        field.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        field.textColor = document.currentColor
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
        activeTextPosition = imagePoint
    }

    @objc private func textFieldAction(_ sender: NSTextField) {
        finalizeTextField()
    }

    private func finalizeTextField() {
        guard let field = activeTextField, let imagePos = activeTextPosition else { return }

        let text = field.stringValue
        field.removeFromSuperview()
        activeTextField = nil
        activeTextPosition = nil

        guard !text.isEmpty else { return }

        let pixelScale = imagePixelScale
        let fontSize = 16.0 * pixelScale
        let annotation = AnnotationItem(kind: .text(TextAnnotation(
            position: imagePos,
            text: text,
            font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            color: document.currentColor
        )))
        document.addAnnotation(annotation)

        // Re-gain first responder for key events
        window?.makeFirstResponder(self)
    }

    // MARK: - Keyboard Events

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "z" {
                if event.modifierFlags.contains(.shift) {
                    document.redo()
                } else {
                    document.undo()
                }
                return
            }
        }

        if event.keyCode == 53 { // ESC
            dragStartPoint = nil
            dragCurrentPoint = nil
            finalizeTextField()
            needsDisplay = true
            return
        }

        super.keyDown(with: event)
    }

    // MARK: - Cursor

    override func resetCursorRects() {
        let drawRect = imageDrawRect
        switch document.selectedTool {
        case .arrow, .rectangle, .blur:
            addCursorRect(drawRect, cursor: .crosshair)
        case .text:
            addCursorRect(drawRect, cursor: .iBeam)
        }
    }

    func toolChanged() {
        window?.invalidateCursorRects(for: self)
        needsDisplay = true
    }
}

// MARK: - NSTextFieldDelegate

extension AnnotationCanvasView: NSTextFieldDelegate {
    nonisolated func controlTextDidEndEditing(_ obj: Notification) {
        MainActor.assumeIsolated {
            finalizeTextField()
        }
    }
}
