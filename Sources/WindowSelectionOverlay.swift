// WindowSelectionOverlay.swift
// MikaScreenSnap
//
// Interactive window picker: hover to highlight, click to capture, ESC to cancel.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
@preconcurrency import ScreenCaptureKit

/// A picker candidate with its geometry already converted to AppKit coordinates.
///
/// Deliberately not `Sendable` — it holds an `SCWindow` and stays on the main actor.
@MainActor
struct WindowTarget {
    let id: CGWindowID
    let scWindow: SCWindow
    /// AppKit global coordinates, bottom-left origin.
    let globalFrame: NSRect
    let appName: String
    let title: String
    let icon: NSImage?

    var label: String {
        title.isEmpty ? appName : "\(appName) — \(title)"
    }

    /// `SCWindow.frame` is global CoreGraphics space: origin at the top-left of the
    /// primary display, y growing downwards. AppKit puts the origin at its bottom-left.
    init?(scWindow: SCWindow) {
        guard let app = scWindow.owningApplication else { return nil }

        self.id = scWindow.windowID
        self.scWindow = scWindow
        self.globalFrame = NSScreen.appKitRect(fromCoreGraphics: scWindow.frame)
        self.appName = app.applicationName
        self.title = scWindow.title ?? ""
        self.icon = NSRunningApplication(processIdentifier: app.processID)?.icon
    }
}

@MainActor
final class WindowSelectionController {
    private var panels: [WindowSelectionPanel] = []
    private var keyMonitor: Any?
    private var spaceObserver: NSObjectProtocol?

    /// Front to back — the first frame containing the pointer wins.
    private var targets: [WindowTarget] = []
    private var hovered: WindowTarget?
    private var onSelect: (@MainActor (SCWindow) -> Void)?
    private var onCancel: (@MainActor () -> Void)?

    func start(
        targets: [WindowTarget],
        onSelect: @escaping @MainActor (SCWindow) -> Void,
        onCancel: @escaping @MainActor () -> Void
    ) {
        self.targets = targets
        self.onSelect = onSelect
        self.onCancel = onCancel

        for screen in NSScreen.screens {
            let panel = WindowSelectionPanel(screen: screen, controller: self)
            panel.makeKeyAndOrderFront(nil)
            panels.append(panel)
        }

        // A local monitor is enough because our panel is key; a global one would need
        // the Input Monitoring permission and fail silently without it.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }  // ESC
            MainActor.assumeIsolated { self?.cancel() }
            return nil
        }

        // The window list goes stale on a space switch, so end the picker instead of
        // highlighting frames that no longer match what is on screen.
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.cancel() }
        }

        // Highlight whatever is already under the pointer, before it moves.
        pointerMoved(to: NSEvent.mouseLocation)
    }

    func dismiss() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let spaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(spaceObserver)
            self.spaceObserver = nil
        }
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
        targets.removeAll()
        hovered = nil
        NSCursor.arrow.set()
    }

    fileprivate func pointerMoved(to globalPoint: NSPoint) {
        let hit = targets.first { $0.globalFrame.contains(globalPoint) }
        guard hit?.id != hovered?.id else { return }
        hovered = hit
        // Broadcast to every panel: a window can straddle two displays.
        for panel in panels {
            panel.setHovered(hit)
        }
    }

    fileprivate func pointerClicked(at globalPoint: NSPoint) {
        guard let target = targets.first(where: { $0.globalFrame.contains(globalPoint) }) else {
            cancel()
            return
        }
        let select = onSelect
        onSelect = nil
        onCancel = nil
        select?(target.scWindow)
    }

    fileprivate func cancel() {
        let cancelled = onCancel
        onSelect = nil
        onCancel = nil
        cancelled?()
    }
}

@MainActor
final class WindowSelectionPanel: NSPanel {
    private var selectionView: WindowSelectionView!

    init(screen: NSScreen, controller: WindowSelectionController) {
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

        selectionView = WindowSelectionView(
            frame: NSRect(origin: .zero, size: screen.frame.size),
            screenFrame: screen.frame,
            controller: controller
        )
        self.contentView = selectionView

        self.setFrame(screen.frame, display: true)
    }

    func setHovered(_ target: WindowTarget?) {
        selectionView.hovered = target
    }
}

@MainActor
final class WindowSelectionView: NSView {
    /// Set by the controller, which broadcasts the hit to every panel.
    var hovered: WindowTarget? {
        didSet { needsDisplay = true }
    }

    private let screenFrame: NSRect
    private weak var controller: WindowSelectionController?

    /// Never fully transparent: the window server hit-tests borderless panels against
    /// their alpha channel, so a clear region would let clicks fall through to the app
    /// underneath instead of selecting it.
    private let dimAlpha: CGFloat = 0.35
    private let highlightAlpha: CGFloat = 0.18

    init(frame: NSRect, screenFrame: NSRect, controller: WindowSelectionController) {
        self.screenFrame = screenFrame
        self.controller = controller
        super.init(frame: frame)

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
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
        addCursorRect(bounds, cursor: .pointingHand)
    }

    /// AppKit global coordinates to this view's coordinates. The panel covers exactly
    /// one screen, so it is a plain offset.
    private func localRect(_ globalRect: NSRect) -> NSRect {
        globalRect.offsetBy(dx: -screenFrame.origin.x, dy: -screenFrame.origin.y)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.black.withAlphaComponent(dimAlpha).setFill()
        bounds.fill()

        guard let hovered else {
            drawHint()
            return
        }

        let rect = localRect(hovered.globalFrame)
        guard rect.intersects(bounds) else {
            drawHint()
            return
        }

        // Replace the dim over the target instead of clearing it — see `dimAlpha`.
        NSGraphicsContext.current?.compositingOperation = .copy
        NSColor.MikaPlus.tealPrimary.withAlphaComponent(highlightAlpha).setFill()
        rect.intersection(bounds).fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver

        let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), xRadius: 10, yRadius: 10)
        borderPath.lineWidth = 3
        NSColor.MikaPlus.tealLight.setStroke()
        borderPath.stroke()

        drawLabel(for: hovered, in: rect)
        drawHint()
    }

    private func drawLabel(for target: WindowTarget, in rect: NSRect) {
        let text = "\(target.label)  ·  \(Int(rect.width)) \u{00D7} \(Int(rect.height)) px"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white,
        ]

        let iconSize: CGFloat = 22
        let padding: CGFloat = 10
        let spacing: CGFloat = 8
        let textSize = (text as NSString).size(withAttributes: attributes)
        let pillWidth = min(padding * 2 + iconSize + spacing + ceil(textSize.width), rect.width - 16, bounds.width - 32)
        let pillHeight = max(iconSize + padding, textSize.height + padding * 2)

        guard pillWidth > iconSize + padding * 2 else { return }

        var origin = NSPoint(
            x: rect.midX - pillWidth / 2,
            y: rect.midY - pillHeight / 2
        )
        origin.x = min(max(origin.x, bounds.minX + 16), bounds.maxX - pillWidth - 16)
        origin.y = min(max(origin.y, bounds.minY + 16), bounds.maxY - pillHeight - 16)

        let pill = NSRect(x: origin.x, y: origin.y, width: pillWidth, height: pillHeight)
        NSColor.black.withAlphaComponent(0.78).setFill()
        NSBezierPath(roundedRect: pill, xRadius: 8, yRadius: 8).fill()

        if let icon = target.icon {
            icon.draw(in: NSRect(
                x: pill.minX + padding,
                y: pill.midY - iconSize / 2,
                width: iconSize,
                height: iconSize
            ))
        }

        let textRect = NSRect(
            x: pill.minX + padding + iconSize + spacing,
            y: pill.midY - textSize.height / 2,
            width: pill.maxX - padding - (pill.minX + padding + iconSize + spacing),
            height: textSize.height
        )
        (text as NSString).draw(in: textRect, withAttributes: attributes)
    }

    private func drawHint() {
        let text = "Click a window to capture  ·  ESC to cancel" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
        ]
        let textSize = text.size(withAttributes: attributes)
        let padding: CGFloat = 12
        let pill = NSRect(
            x: bounds.midX - (textSize.width + padding * 2) / 2,
            y: bounds.maxY - textSize.height - padding * 2 - 40,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )

        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: pill, xRadius: 8, yRadius: 8).fill()
        text.draw(at: NSPoint(x: pill.minX + padding, y: pill.midY - textSize.height / 2), withAttributes: attributes)
    }

    override func mouseMoved(with event: NSEvent) {
        NSCursor.pointingHand.set()
        controller?.pointerMoved(to: NSEvent.mouseLocation)
    }

    override func mouseDown(with event: NSEvent) {
        controller?.pointerClicked(at: NSEvent.mouseLocation)
    }

    override func rightMouseDown(with event: NSEvent) {
        controller?.cancel()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {  // ESC
            controller?.cancel()
        }
    }
}
