import AppKit
@preconcurrency import ScreenCaptureKit

@MainActor
final class CaptureEngine {
    private var areaSelectionPanels: [AreaSelectionPanel] = []
    private var colorLoupeController: ColorLoupeController?
    private var measurementController: MeasurementOverlayController?

    // MARK: - Content Filtering

    /// Windows that must never end up in a capture: our own UI, every app the user
    /// excluded, and the software-rendered pointer overlay.
    private func excludedWindows(in content: SCShareableContent, preferences: AppPreferences?) -> [SCWindow] {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let blocked = preferences?.excludedBundleIdentifiers ?? []
        return content.windows.filter { window in
            if CaptureEngine.isPointerOverlay(window) { return true }
            guard let app = window.owningApplication else { return false }
            return app.processID == ownPID || blocked.contains(app.bundleIdentifier)
        }
    }

    /// Detects the pointer that WindowServer draws as an ordinary window instead of a
    /// hardware cursor — which is what happens once an accessibility pointer (coloured,
    /// enlarged, or driven by Dwell Control) is enabled.
    ///
    /// `SCStreamConfiguration.showsCursor` only suppresses the hardware cursor, so this
    /// overlay would otherwise be baked into every screenshot.
    private static func isPointerOverlay(_ window: SCWindow) -> Bool {
        guard window.title == "Cursor",
              window.owningApplication?.bundleIdentifier.isEmpty ?? false,
              window.windowLayer > 100
        else { return false }
        return true
    }

    /// Captures a still image with the hardware cursor suppressed.
    /// - Parameters:
    ///   - sourceRect: crop in points, top-left origin — pass `.null` to capture everything.
    ///   - pixelWidth/pixelHeight: output size in pixels.
    private func captureCGImage(
        filter: SCContentFilter,
        sourceRect: CGRect,
        pixelWidth: Int,
        pixelHeight: Int,
        shouldBeOpaque: Bool = true
    ) async throws -> CGImage {
        let config = SCStreamConfiguration()
        config.width = pixelWidth
        config.height = pixelHeight
        config.showsCursor = false
        config.shouldBeOpaque = shouldBeOpaque
        if !sourceRect.isNull {
            config.sourceRect = sourceRect
        }

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    // MARK: - Capture

    func captureFullScreen(appState: AppState?) async {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else {
                print("No display found")
                return
            }

            let filter = SCContentFilter(
                display: display,
                excludingWindows: excludedWindows(in: content, preferences: appState?.preferences)
            )

            let cgImage = try await captureCGImage(
                filter: filter,
                sourceRect: .null,
                pixelWidth: Int(display.width) * 2,
                pixelHeight: Int(display.height) * 2
            )
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

            let filter = SCContentFilter(
                display: display,
                excludingWindows: excludedWindows(in: content, preferences: appState?.preferences)
            )

            // Convert from AppKit coordinates (origin bottom-left) to ScreenCaptureKit (origin top-left)
            let displayHeight = CGFloat(display.height)
            let scRect = CGRect(
                x: rect.origin.x,
                y: displayHeight - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )

            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let cgImage = try await captureCGImage(
                filter: filter,
                sourceRect: scRect,
                pixelWidth: Int(rect.width * scale),
                pixelHeight: Int(rect.height * scale)
            )
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))

            postCapture(nsImage, appState: appState)
        } catch {
            print("Area capture failed: \(error)")
        }
    }

    func captureWindow(appState: AppState?) async {
        do {
            let content = try await SCShareableContent.current

            // Find the frontmost window that is neither ours nor an excluded app's
            let skipped = Set(excludedWindows(in: content, preferences: appState?.preferences).map(\.windowID))
            let windows = content.windows.filter {
                !skipped.contains($0.windowID) &&
                $0.isOnScreen &&
                $0.frame.width > 0 && $0.frame.height > 0 &&
                $0.title?.isEmpty == false
            }.sorted { $0.windowLayer < $1.windowLayer }

            guard let targetWindow = windows.first else {
                print("No window found")
                return
            }

            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)
            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let cgImage = try await captureCGImage(
                filter: filter,
                sourceRect: .null,
                pixelWidth: Int(targetWindow.frame.width * scale),
                pixelHeight: Int(targetWindow.frame.height * scale),
                shouldBeOpaque: false
            )
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

            let filter = SCContentFilter(
                display: display,
                excludingWindows: excludedWindows(in: content, preferences: appState?.preferences)
            )

            let displayHeight = CGFloat(display.height)
            let scRect = CGRect(
                x: rect.origin.x,
                y: displayHeight - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )

            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let cgImage = try await captureCGImage(
                filter: filter,
                sourceRect: scRect,
                pixelWidth: Int(rect.width * scale),
                pixelHeight: Int(rect.height * scale)
            )

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

                if appState?.preferences.captureSoundEnabled != false,
                   let sound = NSSound(named: "Tink") {
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
        if appState?.preferences.captureSoundEnabled != false,
           let sound = NSSound(named: "Tink") {
            sound.play()
        }

        // Auto-save to history
        appState?.historyManager.autoSave(image)

        // Open annotation editor
        let controller = AnnotationEditorWindowController(image: image, preferences: appState?.preferences)
        controller.appState = appState
        controller.showWindow(nil)
        appState?.annotationEditorController = controller
    }
}
