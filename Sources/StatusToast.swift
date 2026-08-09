// StatusToast.swift
// MikaScreenSnap
//
// Short-lived, non-blocking status message with auto-dismiss.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
enum StatusToast {
    private static var currentPanel: NSPanel?

    /// Shows a brief message near the top of the screen the pointer is on.
    ///
    /// Unlike `ColorPickerToast` this does not follow the cursor — most capture
    /// failures are triggered by a hotkey, where a message under the pointer is
    /// easy to miss.
    static func show(_ message: String, symbol: String = "exclamationmark.triangle.fill", duration: TimeInterval = 2.5) {
        currentPanel?.orderOut(nil)
        currentPanel = nil

        let view = StatusToastView(message: message, symbol: symbol)
        let size = view.intrinsicContentSize
        let frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        view.frame = frame
        panel.contentView = view

        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        if let visible = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(
                x: visible.midX - size.width / 2,
                y: visible.maxY - size.height - 24
            ))
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        currentPanel = panel

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            panel.animator().alphaValue = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { @MainActor in
            guard currentPanel === panel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                panel.animator().alphaValue = 0
            }, completionHandler: {
                MainActor.assumeIsolated {
                    panel.orderOut(nil)
                    if currentPanel === panel {
                        currentPanel = nil
                    }
                }
            })
        }
    }
}

@MainActor
private final class StatusToastView: NSView {
    private let message: NSString
    private let symbol: String

    private static let textAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        .foregroundColor: NSColor.white,
    ]

    private let horizontalPadding: CGFloat = 14
    private let symbolWidth: CGFloat = 18
    private let symbolSpacing: CGFloat = 8

    init(message: String, symbol: String) {
        self.message = message as NSString
        self.symbol = symbol
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        let textSize = message.size(withAttributes: StatusToastView.textAttributes)
        return NSSize(
            width: horizontalPadding * 2 + symbolWidth + symbolSpacing + ceil(textSize.width),
            height: 38
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let bgPath = CGPath(roundedRect: bounds, cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.85).cgColor)
        ctx.addPath(bgPath)
        ctx.fillPath()

        let textSize = message.size(withAttributes: StatusToastView.textAttributes)
        let textOrigin = NSPoint(
            x: horizontalPadding + symbolWidth + symbolSpacing,
            y: (bounds.height - textSize.height) / 2
        )
        message.draw(at: textOrigin, withAttributes: StatusToastView.textAttributes)

        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
                .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
            let icon = image.withSymbolConfiguration(config) ?? image
            let iconSize = icon.size
            let iconRect = NSRect(
                x: horizontalPadding + (symbolWidth - iconSize.width) / 2,
                y: (bounds.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )
            icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }
}
