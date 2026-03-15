import AppKit
import SwiftUI

/// Custom NSWindow subclass that explicitly accepts key and main status.
@MainActor
private class AnnotationWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AnnotationEditorWindowController {
    private var window: NSWindow?
    private let baseImage: NSImage
    private let document = AnnotationDocument()
    private var canvasView: AnnotationCanvasView?

    init(image: NSImage) {
        self.baseImage = image
    }

    func showWindow(_ sender: Any?) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)

        // Size to fit image, capped at 80% of screen
        let maxW = screenFrame.width * 0.8
        let maxH = screenFrame.height * 0.8
        let imageSize = baseImage.size
        let scale = min(maxW / imageSize.width, maxH / imageSize.height, 1.0)
        let contentW = max(imageSize.width * scale, 600)
        let contentH = max(imageSize.height * scale, 400) + 50  // +50 for toolbar

        // Switch to regular app BEFORE creating the window
        NSApp.setActivationPolicy(.regular)

        let window = AnnotationWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentW, height: contentH),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Annotate Screenshot"
        window.isReleasedWhenClosed = false
        window.acceptsMouseMovedEvents = true
        window.center()

        // Build content
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        // Toolbar (SwiftUI via NSHostingView)
        let toolbarView = AnnotationToolbarView(
            document: document,
            onDone: { [weak self] in self?.done() },
            onSave: { [weak self] in self?.save() },
            onToolChanged: { [weak self] in self?.canvasView?.toolChanged() }
        )
        let toolbarHosting = NSHostingView(rootView: toolbarView)
        toolbarHosting.translatesAutoresizingMaskIntoConstraints = false

        // Canvas
        let canvas = AnnotationCanvasView(baseImage: baseImage, document: document)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        self.canvasView = canvas

        contentView.addSubview(toolbarHosting)
        contentView.addSubview(canvas)

        NSLayoutConstraint.activate([
            toolbarHosting.topAnchor.constraint(equalTo: contentView.topAnchor),
            toolbarHosting.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbarHosting.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            toolbarHosting.heightAnchor.constraint(equalToConstant: 50),

            canvas.topAnchor.constraint(equalTo: toolbarHosting.bottomAnchor),
            canvas.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            canvas.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        window.contentView = contentView
        self.window = window

        // Activate app and show window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    private func done() {
        guard let finalImage = AnnotationRenderer.renderFinalImage(
            baseImage: baseImage, annotations: document.annotations
        ) else { return }

        ClipboardManager.copyToClipboard(finalImage)
        close()
    }

    private func save() {
        guard let finalImage = AnnotationRenderer.renderFinalImage(
            baseImage: baseImage, annotations: document.annotations
        ) else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        savePanel.nameFieldStringValue = "MikaSnap_annotated_\(timestamp).png"

        savePanel.beginSheetModal(for: window!) { response in
            MainActor.assumeIsolated {
                if response == .OK, let url = savePanel.url {
                    ClipboardManager.saveToFile(finalImage, url: url)
                }
            }
        }
    }

    private func close() {
        window?.orderOut(nil)
        window = nil

        // Switch back to accessory policy (menubar-only)
        NSApp.setActivationPolicy(.accessory)
    }
}
