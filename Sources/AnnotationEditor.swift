import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
    private let store = AnnotationStore()
    private var canvasView: AnnotationCanvasView?
    private var keyMonitor: Any?
    weak var appState: AppState?

    init(image: NSImage, preferences: AppPreferences? = nil) {
        self.baseImage = image
        if let prefs = preferences {
            store.selectedTool = DrawingToolType(rawValue: prefs.defaultAnnotationTool) ?? .arrow
            store.currentColor = prefs.defaultStrokeNSColor
            store.currentStrokeWidth = prefs.defaultStrokeWidth
        }
    }

    deinit {
        // Remove event monitor - handled in close()
    }

    func showWindow(_ sender: Any?) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)

        // Size to fit image, capped at 80% of screen
        let maxW = screenFrame.width * 0.8
        let maxH = screenFrame.height * 0.8
        let imageSize = baseImage.size
        let scale = min(maxW / imageSize.width, maxH / imageSize.height, 1.0)
        let contentW = max(imageSize.width * scale, 600)
        let contentH = max(imageSize.height * scale, 400) + 82  // +50 toolbar + 32 bottom bar

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

        // Toolbar (SwiftUI)
        let toolbarView = AnnotationToolbarView(
            store: store,
            onToolChanged: { [weak self] in self?.canvasView?.toolChanged() },
            onExtractText: { [weak self] in self?.startOCRSelection() },
            onPin: { [weak self] in self?.pinScreenshot() }
        )
        let toolbarHosting = NSHostingView(rootView: toolbarView)
        toolbarHosting.translatesAutoresizingMaskIntoConstraints = false

        // Canvas
        let canvas = AnnotationCanvasView(baseImage: baseImage, store: store)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        self.canvasView = canvas

        // Bottom Bar (SwiftUI)
        let cgImage = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let imgW = cgImage?.width ?? Int(baseImage.size.width)
        let imgH = cgImage?.height ?? Int(baseImage.size.height)

        let bottomBarView = AnnotationBottomBarView(
            store: store,
            imageWidth: imgW,
            imageHeight: imgH,
            onCopy: { [weak self] in self?.copyToClipboard() },
            onSave: { [weak self] in self?.save() },
            onSaveAs: { [weak self] in self?.saveAs() },
            onDiscard: { [weak self] in self?.discard() },
            onPin: { [weak self] in self?.pinScreenshot() }
        )
        let bottomBarHosting = NSHostingView(rootView: bottomBarView)
        bottomBarHosting.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(toolbarHosting)
        contentView.addSubview(canvas)
        contentView.addSubview(bottomBarHosting)

        NSLayoutConstraint.activate([
            toolbarHosting.topAnchor.constraint(equalTo: contentView.topAnchor),
            toolbarHosting.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbarHosting.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            toolbarHosting.heightAnchor.constraint(equalToConstant: 50),

            canvas.topAnchor.constraint(equalTo: toolbarHosting.bottomAnchor),
            canvas.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            canvas.bottomAnchor.constraint(equalTo: bottomBarHosting.topAnchor),

            bottomBarHosting.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomBarHosting.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomBarHosting.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomBarHosting.heightAnchor.constraint(equalToConstant: 32),
        ])

        window.contentView = contentView
        self.window = window

        // Keyboard shortcuts via local event monitor
        setupKeyboardMonitor()

        // Activate and show
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    // MARK: - Keyboard Monitor

    private func setupKeyboardMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKeyDown(event) ? nil : event
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasCmd = flags.contains(.command)
        let hasShift = flags.contains(.shift)
        let char = event.charactersIgnoringModifiers?.lowercased() ?? ""

        // Don't intercept if a text field is first responder
        if window?.firstResponder is NSTextView {
            // But still handle Escape
            if event.keyCode == 53 {
                canvasView?.finalizeActiveTextField()
                return true
            }
            return false
        }

        // Cmd+Z / Cmd+Shift+Z — Undo/Redo
        if hasCmd && char == "z" {
            if hasShift {
                store.undoManager.redo()
            } else {
                store.undoManager.undo()
            }
            canvasView?.needsDisplay = true
            return true
        }

        // Cmd+C — Copy
        if hasCmd && char == "c" {
            copyToClipboard()
            return true
        }

        // Cmd+S — Save
        if hasCmd && !hasShift && char == "s" {
            save()
            return true
        }

        // Cmd+Shift+S — Save As
        if hasCmd && hasShift && char == "s" {
            saveAs()
            return true
        }

        // Cmd+= / Cmd+- / Cmd+0 — Zoom
        if hasCmd && (char == "=" || char == "+") {
            canvasView?.zoomIn()
            return true
        }
        if hasCmd && char == "-" {
            canvasView?.zoomOut()
            return true
        }
        if hasCmd && char == "0" {
            canvasView?.zoomToFit()
            return true
        }

        // Delete/Backspace — delete selected
        if event.keyCode == 51 || event.keyCode == 117 {
            store.deleteSelected()
            canvasView?.needsDisplay = true
            return true
        }

        // Escape — cancel OCR selection or close
        if event.keyCode == 53 {
            if canvasView?.isOCRSelectionMode == true {
                canvasView?.isOCRSelectionMode = false
                canvasView?.needsDisplay = true
                return true
            }

            if store.annotations.isEmpty {
                // Quick capture: copy original to clipboard and close
                ClipboardManager.copyToClipboard(baseImage)
                close()
            } else if store.hasUnsavedChanges {
                showDiscardConfirmation()
            } else {
                close()
            }
            return true
        }

        // Tool shortcuts (only when no cmd modifier)
        if !hasCmd {
            let toolMap: [String: DrawingToolType] = [
                "v": .select, "a": .arrow, "r": .rectangle, "e": .ellipse,
                "l": .line, "f": .freehand, "t": .text, "h": .highlight,
                "b": .blur, "x": .pixelate, "m": .measure,
            ]
            if let tool = toolMap[char] {
                store.selectedTool = tool
                canvasView?.toolChanged()
                return true
            }
        }

        return false
    }

    // MARK: - OCR in Editor

    private func startOCRSelection() {
        guard let canvasView else { return }
        canvasView.isOCRSelectionMode = true
        canvasView.onOCRSelection = { [weak self] rect in
            self?.performOCROnRegion(rect)
        }
        canvasView.needsDisplay = true
    }

    private func performOCROnRegion(_ rect: CGRect) {
        guard let cgBase = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        // Clamp rect to image bounds
        let imageBounds = CGRect(x: 0, y: 0, width: cgBase.width, height: cgBase.height)
        let clampedRect = rect.intersection(imageBounds)
        guard !clampedRect.isNull, clampedRect.width > 0, clampedRect.height > 0 else { return }

        guard let cropped = cgBase.cropping(to: clampedRect) else { return }

        Task {
            do {
                let text = try await OCREngine.recognizeText(in: cropped)
                if !text.isEmpty {
                    let resultPanel = OCRResultPanel(text: text)
                    resultPanel.makeKeyAndOrderFront(nil)
                }
            } catch {
                print("OCR failed: \(error)")
            }
        }
    }

    // MARK: - Pin

    private func pinScreenshot() {
        guard let appState else { return }

        let finalImage: NSImage
        if store.annotations.isEmpty {
            finalImage = baseImage
        } else {
            guard let rendered = AnnotationRenderer.renderFinalImage(
                baseImage: baseImage, annotations: store.annotations
            ) else { return }
            finalImage = rendered
        }

        _ = PinnedScreenshotManager.pinImage(finalImage, appState: appState)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        guard let finalImage = AnnotationRenderer.renderFinalImage(
            baseImage: baseImage, annotations: store.annotations
        ) else { return }
        ClipboardManager.copyToClipboard(finalImage)
        close()
    }

    private func save() {
        guard let finalImage = AnnotationRenderer.renderFinalImage(
            baseImage: baseImage, annotations: store.annotations
        ) else { return }
        ClipboardManager.copyToClipboard(finalImage)
        ClipboardManager.saveToDesktop(finalImage)
        close()
    }

    private func saveAs() {
        guard let finalImage = AnnotationRenderer.renderFinalImage(
            baseImage: baseImage, annotations: store.annotations
        ) else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        savePanel.nameFieldStringValue = "MikaSnap_annotated_\(timestamp).png"

        guard let win = window else { return }
        savePanel.beginSheetModal(for: win) { response in
            MainActor.assumeIsolated {
                if response == .OK, let url = savePanel.url {
                    ClipboardManager.saveToFile(finalImage, url: url)
                }
            }
        }
    }

    private func discard() {
        if store.hasUnsavedChanges {
            showDiscardConfirmation()
        } else {
            close()
        }
    }

    private func showDiscardConfirmation() {
        guard let win = window else { return }
        let alert = NSAlert()
        alert.messageText = "Discard Changes?"
        alert.informativeText = "Your annotations will be lost."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")

        alert.beginSheetModal(for: win) { response in
            MainActor.assumeIsolated {
                if response == .alertFirstButtonReturn {
                    self.close()
                }
            }
        }
    }

    private func close() {
        // Save last used tool if enabled
        if let prefs = appState?.preferences, prefs.rememberLastTool {
            prefs.defaultAnnotationTool = store.selectedTool.rawValue
        }

        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
    }
}
