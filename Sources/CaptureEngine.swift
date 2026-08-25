import AppKit
@preconcurrency import ScreenCaptureKit

enum CaptureError: Error {
    case noDisplay
}

@MainActor
final class CaptureEngine {
    private var areaSelectionPanels: [AreaSelectionPanel] = []
    private var windowSelectionController: WindowSelectionController?
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
        // The overlay is owned by WindowServer, which SCK may report as a nil
        // application — treat that like the empty bundle id it otherwise carries.
        guard window.title == "Cursor",
              window.owningApplication?.bundleIdentifier.isEmpty ?? true,
              window.windowLayer > 100
        else { return false }
        return true
    }

    /// Window layers that hold real app windows: from `kCGNormalWindowLevel` (0) up to
    /// just below `kCGDockWindowLevel` (20). Excludes desktop, wallpaper and backstop
    /// windows (large negative layers) as well as the Dock, menubar (24), status items
    /// (25) and open menus (101).
    private static let selectableWindowLayers: Range<Int> = 0..<20

    /// System UI that owns normal-layer windows but is never a useful capture target.
    private static let nonTargetBundleIdentifiers: Set<String> = [
        "com.apple.dock",                   // Dock, Mission Control, App Exposé
        "com.apple.WindowManager",          // Stage Manager
        "com.apple.wallpaper.agent",        // Wallpaper (macOS 14+)
        "com.apple.notificationcenterui",
        "com.apple.controlcenter",
    ]

    /// Every window that can serve as a capture target, ordered front to back.
    ///
    /// `SCShareableContent.windows` already arrives front to back, so the order is
    /// preserved by sorting on the original index as a tiebreaker — `Array.sorted` is
    /// not stable and all ordinary app windows share layer 0.
    private func selectableWindows(in content: SCShareableContent, preferences: AppPreferences?) -> [SCWindow] {
        let excludedIDs = Set(excludedWindows(in: content, preferences: preferences).map(\.windowID))
        let minimumSide: CGFloat = 40

        return content.windows.enumerated()
            .filter { _, window in
                guard !excludedIDs.contains(window.windowID),
                      window.isOnScreen,
                      CaptureEngine.selectableWindowLayers.contains(window.windowLayer),
                      window.frame.width >= minimumSide,
                      window.frame.height >= minimumSide,
                      let app = window.owningApplication,
                      !app.bundleIdentifier.isEmpty,
                      !CaptureEngine.nonTargetBundleIdentifiers.contains(app.bundleIdentifier)
                else { return false }
                return true
            }
            .sorted { lhs, rhs in
                if lhs.element.windowLayer != rhs.element.windowLayer {
                    return lhs.element.windowLayer > rhs.element.windowLayer  // higher layer is further front
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// Pairs an `SCDisplay` with the `NSScreen` it corresponds to.
    ///
    /// Every capture used to run against `content.displays.first`, which is neither the
    /// screen the pointer is on nor the one a selection was drawn on — on a multi-display
    /// setup that meant the wrong screen and, for area captures, the wrong crop.
    private func display(in content: SCShareableContent, matching screen: NSScreen?) -> (SCDisplay, NSScreen)? {
        guard let screen, let displayID = screen.displayID else {
            guard let fallback = content.displays.first,
                  let fallbackScreen = NSScreen.screens.first else { return nil }
            return (fallback, fallbackScreen)
        }

        if let match = content.displays.first(where: { $0.displayID == displayID }) {
            return (match, screen)
        }
        guard let fallback = content.displays.first else { return nil }
        return (fallback, screen)
    }

    /// Shareable content without the desktop and wallpaper layer, which are never
    /// meaningful capture targets and used to win the window search.
    private func shareableWindowContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
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

    /// Captures the display the pointer is on.
    func captureFullScreen(appState: AppState?) async {
        do {
            let content = try await SCShareableContent.current
            guard let (display, _) = display(in: content, matching: NSScreen.underPointer) else {
                CaptureLog.report("No display found", message: "No display available")
                return
            }

            let filter = SCContentFilter(
                display: display,
                excludingWindows: excludedWindows(in: content, preferences: appState?.preferences)
            )

            // Scale comes from the filter, not a hard-coded 2 — a display that is not
            // Retina used to be captured at twice its real resolution.
            let scale = CGFloat(filter.pointPixelScale)
            let cgImage = try await captureCGImage(
                filter: filter,
                sourceRect: .null,
                pixelWidth: Int((CGFloat(display.width) * scale).rounded()),
                pixelHeight: Int((CGFloat(display.height) * scale).rounded())
            )
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: display.width, height: display.height))

            postCapture(nsImage, appState: appState)
        } catch {
            CaptureLog.report(error, action: "Full screen capture")
        }
    }

    /// Captures a dragged region, on whichever display it was drawn.
    ///
    /// `rect` arrives in global AppKit coordinates; both the crop and the scale are taken
    /// from the display that actually holds it.
    func captureArea(rect: CGRect, appState: AppState?) async {
        do {
            let cgImage = try await captureRegion(rect: rect, appState: appState)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))
            postCapture(nsImage, appState: appState)
        } catch {
            CaptureLog.report(error, action: "Area capture")
        }
    }

    /// Shared by area capture and text capture.
    private func captureRegion(rect: CGRect, appState: AppState?) async throws -> CGImage {
        let content = try await SCShareableContent.current
        guard let (display, screen) = display(in: content, matching: NSScreen.containing(rect)) else {
            throw CaptureError.noDisplay
        }

        let filter = SCContentFilter(
            display: display,
            excludingWindows: excludedWindows(in: content, preferences: appState?.preferences)
        )

        let sourceRect = screen.sourceRect(forAppKitRect: rect)
        let scale = CGFloat(filter.pointPixelScale)

        return try await captureCGImage(
            filter: filter,
            sourceRect: sourceRect,
            pixelWidth: Int((rect.width * scale).rounded()),
            pixelHeight: Int((rect.height * scale).rounded())
        )
    }

    /// Captures the frontmost window of the active app without any interaction.
    func captureWindow(appState: AppState?) async {
        do {
            let content = try await shareableWindowContent()
            let candidates = selectableWindows(in: content, preferences: appState?.preferences)

            // Our own app never activates (.accessory), so the previously active app is
            // still frontmost when the hotkey fires. Falling back to the front of the
            // list covers the menubar path, where our own windows are filtered out anyway.
            let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
            let targetWindow = candidates.first { $0.owningApplication?.processID == frontPID }
                ?? candidates.first

            guard let targetWindow else {
                CaptureLog.report("No capturable window found", message: "No window to capture")
                return
            }

            await captureWindow(targetWindow, appState: appState)
        } catch {
            CaptureLog.report(error, action: "Window capture")
        }
    }

    /// Captures a single window.
    ///
    /// Size and scale come from the content filter rather than `NSScreen.main`, so a
    /// window on a display with a different backing scale is captured at its own
    /// resolution.
    private func captureWindow(_ window: SCWindow, appState: AppState?) async {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let contentRect = filter.contentRect
        let scale = CGFloat(filter.pointPixelScale)
        let pixelWidth = Int((contentRect.width * scale).rounded())
        let pixelHeight = Int((contentRect.height * scale).rounded())

        guard pixelWidth > 0, pixelHeight > 0 else {
            CaptureLog.report(
                "Window \(window.windowID) has an empty content rect",
                message: "Window has no capturable content"
            )
            return
        }

        do {
            let cgImage = try await captureCGImage(
                filter: filter,
                sourceRect: .null,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight,
                shouldBeOpaque: false
            )
            let nsImage = NSImage(cgImage: cgImage, size: contentRect.size)

            postCapture(nsImage, appState: appState)
        } catch {
            CaptureLog.report(error, action: "Window capture")
        }
    }

    // MARK: - Window Selection

    /// Shows the interactive window picker: hover to highlight, click to capture.
    func startWindowSelection(appState: AppState?) {
        dismissWindowSelection()

        Task { @MainActor in
            do {
                let content = try await shareableWindowContent()
                let windows = selectableWindows(in: content, preferences: appState?.preferences)
                let targets = windows.compactMap { WindowTarget(scWindow: $0) }

                guard !targets.isEmpty else {
                    CaptureLog.report("No capturable window found", message: "No window to capture")
                    return
                }

                let controller = WindowSelectionController()
                self.windowSelectionController = controller
                controller.start(
                    targets: targets,
                    onSelect: { [weak self] window in
                        guard let self else { return }
                        self.dismissWindowSelection()
                        // Let the panels disappear before the editor opens.
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(100))
                            await self.captureWindow(window, appState: appState)
                        }
                    },
                    onCancel: { [weak self] in
                        self?.dismissWindowSelection()
                    }
                )
            } catch {
                CaptureLog.report(error, action: "Window picker")
            }
        }
    }

    func dismissWindowSelection() {
        windowSelectionController?.dismiss()
        windowSelectionController = nil
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
            let cgImage = try await captureRegion(rect: rect, appState: appState)
            let recognizedText = try await OCREngine.recognizeText(in: cgImage)

            guard !recognizedText.isEmpty else {
                // Silence used to be the answer here, which is indistinguishable from the
                // feature not having fired at all.
                StatusToast.show("No text found in selection")
                return
            }

            ClipboardManager.copyToClipboard(text: recognizedText, concealed: true)

            let resultPanel = OCRResultPanel(text: recognizedText)
            resultPanel.makeKeyAndOrderFront(nil)

            if appState?.preferences.captureSoundEnabled != false,
               let sound = NSSound(named: "Tink") {
                sound.play()
            }
        } catch {
            CaptureLog.report(error, action: "Text capture")
        }
    }

    // MARK: - Color Picker

    func startColorPicker(appState: AppState?) {
        guard let appState else { return }

        Task { @MainActor in
            do {
                // Snapshot the screen before any overlay exists, so nothing of ours
                // can end up under the loupe.
                let content = try await SCShareableContent.current
                let engine = ColorPickerEngine()
                try await engine.loadSnapshots(
                    excludedWindows: excludedWindows(in: content, preferences: appState.preferences),
                    content: content
                )

                let controller = ColorLoupeController()
                self.colorLoupeController = controller

                controller.start(appState: appState, engine: engine) { [weak self] _ in
                    self?.colorLoupeController = nil
                }
            } catch {
                CaptureLog.report(error, action: "Colour picker")
            }
        }
    }

    // MARK: - Measurement

    func startMeasurement() {
        measurementController?.dismiss()
        let controller = MeasurementOverlayController()
        self.measurementController = controller
        controller.start { [weak self] in
            self?.measurementController = nil
        }
    }

    // MARK: - Post-Capture

    private func postCapture(_ image: NSImage, appState: AppState?) {
        appState?.lastCapture = image

        // Play capture sound
        if appState?.preferences.captureSoundEnabled != false,
           let sound = NSSound(named: "Tink") {
            sound.play()
        }

        // Auto-save to history. The editor keeps the URL so it can replace this file with
        // the edited image — what lands here is the untouched original.
        let savedURL = appState?.historyManager.autoSave(image)

        // Open annotation editor
        let controller = AnnotationEditorWindowController(image: image, preferences: appState?.preferences)
        controller.appState = appState
        controller.autoSavedURL = savedURL
        controller.showWindow(nil)
        appState?.annotationEditorController = controller
    }
}
