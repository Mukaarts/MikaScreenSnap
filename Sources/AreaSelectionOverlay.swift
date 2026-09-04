import AppKit

@MainActor
final class AreaSelectionPanel: NSPanel {
    private var selectionView: AreaSelectionView!

    /// - Parameter onCancel: called when the user backs out — Escape, or a click that
    ///   turns out to be too small to be a selection.
    ///
    ///   The panel used to answer a cancel by ordering *itself* out. On a second display
    ///   that left the other panel standing: a dimmed screen that swallows every click,
    ///   with no visible way back. Cancelling has to reach whoever opened the set, so the
    ///   caller passes the dismissal in.
    init(screen: NSScreen,
         onSelection: @escaping @MainActor (CGRect) -> Void,
         onCancel: @escaping @MainActor () -> Void) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        selectionView = AreaSelectionView(frame: screen.frame,
                                          onSelection: onSelection,
                                          onCancel: onCancel)
        self.contentView = selectionView

        self.setFrame(screen.frame, display: true)
    }
}

@MainActor
final class AreaSelectionView: NSView {
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var onSelection: (@MainActor (CGRect) -> Void)?
    private var onCancel: (@MainActor () -> Void)?
    private var isDragging = false

    init(frame: NSRect, onSelection: @escaping @MainActor (CGRect) -> Void, onCancel: @escaping @MainActor () -> Void) {
        self.onSelection = onSelection
        self.onCancel = onCancel
        super.init(frame: frame)

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Semi-transparent overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        guard let start = startPoint, let current = currentPoint else { return }
        let selectionRect = makeRect(from: start, to: current)
        guard selectionRect.width > 1, selectionRect.height > 1 else { return }

        // Punching the hole switches the context to .copy. That used to be undone by a
        // plain assignment further down, which made every stroke after it depend on one
        // line being reached; save/restore scopes the change to the fill that needs it.
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.compositingOperation = .copy
        NSColor.clear.setFill()
        selectionRect.fill()
        NSGraphicsContext.restoreGraphicsState()

        // Dashed border
        let borderPath = NSBezierPath(rect: selectionRect)
        borderPath.lineWidth = 1.5
        let dashPattern: [CGFloat] = [6, 4]
        borderPath.setLineDash(dashPattern, count: 2, phase: 0)
        NSColor.white.setStroke()
        borderPath.stroke()

        Self.drawSizeLabel(for: selectionRect, in: bounds)
    }

    // MARK: - Size readout

    static let sizeLabelFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
    static let sizeLabelPadding: CGFloat = 6
    /// Distance between the selection edge and the readout.
    static let sizeLabelGap: CGFloat = 4

    static func sizeLabelText(for rect: NSRect) -> String {
        "\(Int(rect.width)) \u{00D7} \(Int(rect.height)) px"
    }

    static func sizeLabelSize(for text: String) -> NSSize {
        let textSize = (text as NSString).size(withAttributes: [.font: sizeLabelFont])
        return NSSize(width: textSize.width + sizeLabelPadding * 2,
                      height: textSize.height + sizeLabelPadding * 2)
    }

    /// Where the readout sits for a given selection — pure, so it can be tested.
    ///
    /// One case was wrong, and it is the common one: **a selection that reaches the top
    /// of the screen.** With no room below, the old code moved the label to
    /// `rect.maxY + 4` — past `bounds.maxY`, off the view. A label drawn outside the view
    /// is indistinguishable from one that was never drawn, which is why nobody noticed.
    /// Dragging from the menu bar downwards hits it every time.
    ///
    /// Order matters: below the selection, else above it, else inside it at the top (a
    /// selection spanning the whole height has no outside left), and a clamp on both axes
    /// as the last word. The clamp is what makes the property hold rather than four
    /// separate cases each holding by itself.
    static func sizeLabelRect(for selection: NSRect, in bounds: NSRect, labelSize: NSSize) -> NSRect {
        var origin = NSPoint(x: selection.maxX - labelSize.width,
                             y: selection.minY - labelSize.height - sizeLabelGap)

        if origin.y < bounds.minY {
            origin.y = selection.maxY + sizeLabelGap
        }
        if origin.y + labelSize.height > bounds.maxY {
            origin.y = selection.maxY - labelSize.height - sizeLabelGap
        }

        origin.x = min(max(origin.x, bounds.minX), max(bounds.minX, bounds.maxX - labelSize.width))
        origin.y = min(max(origin.y, bounds.minY), max(bounds.minY, bounds.maxY - labelSize.height))
        return NSRect(origin: origin, size: labelSize)
    }

    static func drawSizeLabel(for rect: NSRect, in bounds: NSRect) {
        let text = sizeLabelText(for: rect)
        let labelRect = sizeLabelRect(for: rect, in: bounds, labelSize: sizeLabelSize(for: text))

        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4).fill()

        (text as NSString).draw(
            at: NSPoint(x: labelRect.minX + sizeLabelPadding, y: labelRect.minY + sizeLabelPadding),
            withAttributes: [.font: sizeLabelFont, .foregroundColor: NSColor.white]
        )
    }

    private func makeRect(from p1: NSPoint, to p2: NSPoint) -> NSRect {
        let x = min(p1.x, p2.x)
        let y = min(p1.y, p2.y)
        let w = abs(p1.x - p2.x)
        let h = abs(p1.y - p2.y)
        return NSRect(x: x, y: y, width: w, height: h)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        currentPoint = point
        isDragging = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging, let start = startPoint else { return }
        isDragging = false

        let end = convert(event.locationInWindow, from: nil)
        let selectionRect = makeRect(from: start, to: end)

        if selectionRect.width > 3 && selectionRect.height > 3 {
            // Convert to screen coordinates
            guard let window = self.window else { return }
            let screenRect = window.convertToScreen(selectionRect)
            onSelection?(screenRect)
        } else {
            // Too small to mean anything — treat it as a cancel, and actually cancel.
            //
            // This branch used to clear the two points and stop. `onCancel` is what takes
            // the panels down, so a stray click left the screen dimmed and swallowing
            // every click, on every display at once, with Escape the only way out. It
            // reads exactly like a hang.
            startPoint = nil
            currentPoint = nil
            needsDisplay = true
            onCancel?()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            startPoint = nil
            currentPoint = nil
            isDragging = false
            needsDisplay = true
            onCancel?()
        }
    }

    override func mouseMoved(with event: NSEvent) {
        // Keep crosshair cursor active
    }
}
