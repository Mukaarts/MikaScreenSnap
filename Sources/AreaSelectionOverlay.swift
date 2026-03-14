import AppKit

@MainActor
final class AreaSelectionPanel: NSPanel {
    private var selectionView: AreaSelectionView!

    init(screen: NSScreen, onSelection: @escaping @MainActor (CGRect) -> Void) {
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

        selectionView = AreaSelectionView(frame: screen.frame, onSelection: onSelection, onCancel: { [weak self] in
            self?.orderOut(nil)
        })
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

        // If we have a selection, cut it out
        if let start = startPoint, let current = currentPoint {
            let selectionRect = makeRect(from: start, to: current)

            if selectionRect.width > 1 && selectionRect.height > 1 {
                // Clear the selected area
                NSGraphicsContext.current?.compositingOperation = .copy
                NSColor.clear.setFill()
                selectionRect.fill()

                // Reset compositing
                NSGraphicsContext.current?.compositingOperation = .sourceOver

                // Dashed border
                let borderPath = NSBezierPath(rect: selectionRect)
                borderPath.lineWidth = 1.5
                let dashPattern: [CGFloat] = [6, 4]
                borderPath.setLineDash(dashPattern, count: 2, phase: 0)
                NSColor.white.setStroke()
                borderPath.stroke()

                // Size label
                drawSizeLabel(for: selectionRect)
            }
        }
    }

    private func drawSizeLabel(for rect: NSRect) {
        let w = Int(rect.width)
        let h = Int(rect.height)
        let text = "\(w) \u{00D7} \(h) px"

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]

        let textSize = (text as NSString).size(withAttributes: attributes)
        let padding: CGFloat = 6
        let labelWidth = textSize.width + padding * 2
        let labelHeight = textSize.height + padding * 2

        // Position below and to the right of the selection
        var labelOrigin = NSPoint(
            x: rect.maxX - labelWidth,
            y: rect.minY - labelHeight - 4
        )

        // Keep on screen
        if labelOrigin.y < bounds.minY {
            labelOrigin.y = rect.maxY + 4
        }
        if labelOrigin.x < bounds.minX {
            labelOrigin.x = rect.minX
        }

        let labelRect = NSRect(x: labelOrigin.x, y: labelOrigin.y, width: labelWidth, height: labelHeight)

        // Background
        let bgPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.7).setFill()
        bgPath.fill()

        // Text
        let textOrigin = NSPoint(x: labelRect.minX + padding, y: labelRect.minY + padding)
        (text as NSString).draw(at: textOrigin, withAttributes: attributes)
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
            // Too small, treat as cancel
            startPoint = nil
            currentPoint = nil
            needsDisplay = true
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
