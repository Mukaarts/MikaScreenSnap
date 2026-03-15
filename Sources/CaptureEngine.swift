import AppKit
@preconcurrency import ScreenCaptureKit

@MainActor
final class CaptureEngine {
    private var areaSelectionPanels: [AreaSelectionPanel] = []
    private var colorLoupeController: ColorLoupeController?
    private var measurementController: MeasurementOverlayController?

    func captureFullScreen(appState: AppState?) async {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else {
                print("No display found")
                return
            }

            let ownPID = ProcessInfo.processInfo.processIdentifier
            let excludedWindows = content.windows.filter { $0.owningApplication?.processID == ownPID }

            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            let config = SCStreamConfiguration()
            config.width = Int(display.width) * 2
            config.height = Int(display.height) * 2
            config.showsCursor = false

            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: display.width, height: display.height))

            postCapture(nsImage, appState: appState)
        } catch {
            print("Full screen capture failed: \(error)")
        }
    }

    func captureArea(rect: CGRect, appState: AppState?) async {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else { return }

            let ownPID = ProcessInfo.processInfo.processIdentifier
            let excludedWindows = content.windows.filter { $0.owningApplication?.processID == ownPID }

            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)

            // Convert from AppKit coordinates (origin bottom-left) to ScreenCaptureKit (origin top-left)
            let displayHeight = CGFloat(display.height)
            let scRect = CGRect(
                x: rect.origin.x,
                y: displayHeight - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )

            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let config = SCStreamConfiguration()
            config.sourceRect = scRect
            config.width = Int(rect.width * scale)
            config.height = Int(rect.height * scale)
            config.showsCursor = false

            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))

            postCapture(nsImage, appState: appState)
        } catch {
            print("Area capture failed: \(error)")
        }
    }

    func captureWindow(appState: AppState?) async {
        do {
            let content = try await SCShareableContent.current

            // Find the frontmost window that isn't ours
            let ownPID = ProcessInfo.processInfo.processIdentifier
            let windows = content.windows.filter {
                $0.owningApplication?.processID != ownPID &&
                $0.isOnScreen &&
                $0.frame.width > 0 && $0.frame.height > 0 &&
                $0.title?.isEmpty == false
            }.sorted { $0.windowLayer < $1.windowLayer }

            guard let targetWindow = windows.first else {
                print("No window found")
                return
            }

            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)
            let config = SCStreamConfiguration()
            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            config.width = Int(targetWindow.frame.width * scale)
            config.height = Int(targetWindow.frame.height * scale)
            config.showsCursor = false
            config.capturesShadowsOnly = false
            config.shouldBeOpaque = false

            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: targetWindow.frame.width, height: targetWindow.frame.height))

            postCapture(nsImage, appState: appState)
        } catch {
            print("Window capture failed: \(error)")
        }
    }

    func startAreaSelection(appState: AppState?) {
        dismissAreaSelection()

        for screen in NSScreen.screens {
            let panel = AreaSelectionPanel(screen: screen) { [weak self] rect in
                guard let self else { return }
                self.dismissAreaSelection()
                // Small delay to let panels disappear before capture
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    await self.captureArea(rect: rect, appState: appState)
                }
            }
            panel.makeKeyAndOrderFront(nil)
            areaSelectionPanels.append(panel)
        }
    }

    func dismissAreaSelection() {
        for panel in areaSelectionPanels {
            panel.orderOut(nil)
        }
        areaSelectionPanels.removeAll()
    }

    // MARK: - Text Capture (OCR)

    func startTextCapture(appState: AppState?) {
        dismissAreaSelection()

        for screen in NSScreen.screens {
            let panel = AreaSelectionPanel(screen: screen) { [weak self] rect in
                guard let self else { return }
                self.dismissAreaSelection()

                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    await self.captureAreaForOCR(rect: rect, appState: appState)
                }
            }
            panel.makeKeyAndOrderFront(nil)
            areaSelectionPanels.append(panel)
        }
    }

    private func captureAreaForOCR(rect: CGRect, appState: AppState?) async {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else { return }

            let ownPID = ProcessInfo.processInfo.processIdentifier
            let excludedWindows = content.windows.filter { $0.owningApplication?.processID == ownPID }

            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)

            let displayHeight = CGFloat(display.height)
            let scRect = CGRect(
                x: rect.origin.x,
                y: displayHeight - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )

            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let config = SCStreamConfiguration()
            config.sourceRect = scRect
            config.width = Int(rect.width * scale)
            config.height = Int(rect.height * scale)
            config.showsCursor = false

            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

            // Run OCR
            let recognizedText = try await OCREngine.recognizeText(in: cgImage)

            if !recognizedText.isEmpty {
                // Copy to clipboard
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(recognizedText, forType: .string)

                // Show result panel
                let resultPanel = OCRResultPanel(text: recognizedText)
                resultPanel.makeKeyAndOrderFront(nil)

                if let sound = NSSound(named: "Tink") {
                    sound.play()
                }
            }
        } catch {
            print("Text capture failed: \(error)")
        }
    }

    // MARK: - Color Picker

    func startColorPicker(appState: AppState?) {
        guard let appState else { return }

        let controller = ColorLoupeController()
        self.colorLoupeController = controller

        controller.start(appState: appState) { [weak self] _ in
            self?.colorLoupeController = nil
        }
    }

    // MARK: - Measurement

    func startMeasurement(appState: AppState?) {
        let controller = MeasurementOverlayController()
        self.measurementController = controller
        controller.start()
    }

    // MARK: - Post-Capture

    private func postCapture(_ image: NSImage, appState: AppState?) {
        appState?.lastCapture = image

        // Play capture sound
        if let sound = NSSound(named: "Tink") {
            sound.play()
        }

        // Auto-save to history
        appState?.historyManager.autoSave(image)

        // Open annotation editor
        let controller = AnnotationEditorWindowController(image: image)
        controller.appState = appState
        controller.showWindow(nil)
        appState?.annotationEditorController = controller
    }
}
