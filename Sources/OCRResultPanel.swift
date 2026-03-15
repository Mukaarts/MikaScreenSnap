// OCRResultPanel.swift
// MikaScreenSnap
//
// HUD-style result panel for OCR text, with copy buttons and auto-dismiss.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
final class OCRResultPanel: NSPanel {
    private var dismissTimer: Timer?
    private var isHovered: Bool = false
    private let resultText: String

    init(text: String) {
        self.resultText = text
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
            styleMask: [.titled, .closable, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        title = "Extracted Text"
        isReleasedWhenClosed = false
        level = .floating
        isMovableByWindowBackground = true

        setupContent()
        center()
        startAutoDismiss()
    }

    private func setupContent() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 300))

        // Scrollable text view
        let scrollView = NSScrollView(frame: NSRect(x: 16, y: 52, width: 388, height: 232))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        let textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.string = resultText
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 4, height: 4)

        scrollView.documentView = textView
        contentView.addSubview(scrollView)

        // Copy button
        let copyButton = NSButton(frame: NSRect(x: 16, y: 12, width: 80, height: 28))
        copyButton.title = "Copy"
        copyButton.bezelStyle = .rounded
        copyButton.target = self
        copyButton.action = #selector(copyText)
        copyButton.autoresizingMask = [.maxXMargin, .maxYMargin]
        contentView.addSubview(copyButton)

        // Copy as Markdown button
        let mdButton = NSButton(frame: NSRect(x: 104, y: 12, width: 150, height: 28))
        mdButton.title = "Copy as Markdown"
        mdButton.bezelStyle = .rounded
        mdButton.target = self
        mdButton.action = #selector(copyAsMarkdown)
        mdButton.autoresizingMask = [.maxXMargin, .maxYMargin]
        contentView.addSubview(mdButton)

        self.contentView = contentView

        // Hover tracking to pause auto-dismiss
        let trackingArea = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(trackingArea)
    }

    @objc private func copyText() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(resultText, forType: .string)
        orderOut(nil)
    }

    @objc private func copyAsMarkdown() {
        let lines = resultText.components(separatedBy: "\n")
        let markdown = lines.map { "- \($0)" }.joined(separator: "\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(markdown, forType: .string)
        orderOut(nil)
    }

    private func startAutoDismiss() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { @MainActor in
                guard let self, !self.isHovered else { return }
                self.orderOut(nil)
            }
        }
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        dismissTimer?.invalidate()
        dismissTimer = nil
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        startAutoDismiss()
    }
}
