// PinnedScreenshotPanel.swift
// MikaScreenSnap
//
// Floating always-on-top panel for pinned screenshots with drag, resize, opacity controls.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class PinnedScreenshotPanel: NSPanel {
    private let image: NSImage
    private let imageView: NSImageView
    private var dragStart: CGPoint?
    private var closeButton: NSButton?
    fileprivate weak var appState: AppState?

    init(image: NSImage, appState: AppState) {
        self.image = image
        self.appState = appState

        // Size to image, capped at 400px wide
        let maxWidth: CGFloat = 400
        let scale = min(maxWidth / image.size.width, 1.0)
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)

        self.imageView = NSImageView(frame: NSRect(origin: .zero, size: size))

        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        isMovableByWindowBackground = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false

        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 6
        imageView.layer?.masksToBounds = true

        let contentView = PinnedContentView(panel: self)
        contentView.frame = NSRect(origin: .zero, size: size)
        contentView.autoresizingMask = [.width, .height]

        imageView.autoresizingMask = [.width, .height]
        contentView.addSubview(imageView)

        // Close button (shown on hover)
        let close = NSButton(frame: NSRect(x: 4, y: size.height - 24, width: 20, height: 20))
        close.bezelStyle = .circular
        close.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")
        close.isBordered = false
        close.target = self
        close.action = #selector(closePanel)
        close.isHidden = true
        close.autoresizingMask = [.maxXMargin, .minYMargin]
        contentView.addSubview(close)
        self.closeButton = close

        self.contentView = contentView
        center()
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.shift) {
            // Shift+drag for resize
            return
        }
        dragStart = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        if event.modifierFlags.contains(.shift) {
            // Proportional resize
            let delta = event.deltaX
            let currentSize = frame.size
            let aspect = currentSize.height / currentSize.width
            let newWidth = max(100, currentSize.width + delta)
            let newHeight = newWidth * aspect
            let newFrame = NSRect(
                x: frame.origin.x,
                y: frame.origin.y - (newHeight - currentSize.height),
                width: newWidth,
                height: newHeight
            )
            setFrame(newFrame, display: true)
            return
        }

        guard let start = dragStart else { return }
        let current = event.locationInWindow
        let dx = current.x - start.x
        let dy = current.y - start.y
        let origin = frame.origin
        setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y + dy))
    }

    override func scrollWheel(with event: NSEvent) {
        // Scroll wheel for opacity
        let delta = event.deltaY * 0.02
        let newAlpha = min(max(alphaValue + delta, 0.2), 1.0)
        alphaValue = newAlpha
    }

    func showCloseButton() {
        closeButton?.isHidden = false
    }

    func hideCloseButton() {
        closeButton?.isHidden = true
    }

    @objc private func closePanel() {
        appState?.pinnedPanels.removeAll { $0 === self }
        orderOut(nil)
    }

    // MARK: - Context Menu

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let copyItem = NSMenuItem(title: "Copy Image", action: #selector(copyImage), keyEquivalent: "")
        copyItem.target = self
        menu.addItem(copyItem)

        let saveItem = NSMenuItem(title: "Save to Desktop", action: #selector(saveImage), keyEquivalent: "")
        saveItem.target = self
        menu.addItem(saveItem)

        let editItem = NSMenuItem(title: "Open in Editor", action: #selector(openInEditor), keyEquivalent: "")
        editItem.target = self
        menu.addItem(editItem)

        menu.addItem(.separator())

        // Opacity submenu
        let opacityMenu = NSMenu()
        for pct in [100, 80, 60, 40, 20] {
            let item = NSMenuItem(title: "\(pct)%", action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.tag = pct
            opacityMenu.addItem(item)
        }
        let opacityItem = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        opacityItem.submenu = opacityMenu
        menu.addItem(opacityItem)

        menu.addItem(.separator())

        let closeItem = NSMenuItem(title: "Close", action: #selector(closePanel), keyEquivalent: "")
        closeItem.target = self
        menu.addItem(closeItem)

        NSMenu.popUpContextMenu(menu, with: event, for: contentView!)
    }

    @objc private func copyImage() {
        ClipboardManager.copyToClipboard(image)
    }

    @objc private func saveImage() {
        ClipboardManager.saveToDesktop(image)
    }

    @objc private func openInEditor() {
        let controller = AnnotationEditorWindowController(image: image)
        controller.showWindow(nil)
        appState?.annotationEditorController = controller
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        alphaValue = CGFloat(sender.tag) / 100.0
    }
}

// MARK: - Content View with Hover Tracking

@MainActor
private final class PinnedContentView: NSView {
    weak var panel: PinnedScreenshotPanel?

    init(panel: PinnedScreenshotPanel) {
        self.panel = panel
        super.init(frame: .zero)

        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func mouseEntered(with event: NSEvent) {
        panel?.showCloseButton()
    }

    override func mouseExited(with event: NSEvent) {
        panel?.hideCloseButton()
    }

    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            panel?.appState?.pinnedPanels.removeAll { $0 === panel }
            panel?.orderOut(nil)
        }
    }
}
