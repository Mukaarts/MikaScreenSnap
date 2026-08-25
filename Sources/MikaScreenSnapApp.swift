import SwiftUI
@preconcurrency import ScreenCaptureKit

@Observable
@MainActor
final class AppState {
    var captureEngine: CaptureEngine
    var lastCapture: NSImage?
    var annotationEditorController: AnnotationEditorWindowController?
    var pinnedPanels: [PinnedScreenshotPanel] = []
    var historyManager: ScreenshotHistoryManager
    var preferences: AppPreferences
    var colorHistory: ColorHistoryManager
    var historyBrowserController: HistoryBrowserWindowController?
    var colorLoupeController: ColorLoupeController?
    var measurementController: MeasurementOverlayController?
    var preferencesController: PreferencesWindowController?
    var aboutController: AboutWindowController?
    /// Created on first use, not at launch.
    ///
    /// Sparkle's controller reaches for the surrounding app bundle as soon as it exists,
    /// which blocks anywhere there is none — a test process, for instance. Nothing needs
    /// the updater before the menu or Preferences ask for it.
    /// (`@Observable` rules out `lazy`, and observing it would buy nothing: `SparkleUpdater`
    /// is not observable itself.)
    @ObservationIgnored private var storedSparkleUpdater: SparkleUpdater?

    var sparkleUpdater: SparkleUpdater {
        if let storedSparkleUpdater { return storedSparkleUpdater }
        let updater = SparkleUpdater()
        storedSparkleUpdater = updater
        return updater
    }
    var launchAtLoginManager: LaunchAtLoginManager
    var onboardingController: OnboardingWindowController?

    init() {
        let prefs = AppPreferences()
        self.preferences = prefs
        self.captureEngine = CaptureEngine()
        self.historyManager = ScreenshotHistoryManager(preferences: prefs)
        self.colorHistory = ColorHistoryManager()
        self.launchAtLoginManager = LaunchAtLoginManager()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var hotkeyManager: HotkeyManager?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !appState.preferences.hasCompletedOnboarding {
            showOnboarding()
        } else if !CGPreflightScreenCaptureAccess() {
            checkScreenCapturePermission()
        }

        // Restore pinned screenshots
        PinnedScreenshotManager.restorePins(appState: appState)

        // Let the updater ask before it closes an editor holding unsaved annotations.
        appState.sparkleUpdater.hasUnsavedWork = { [weak appState] in
            appState?.annotationEditorController?.hasUnsavedChanges ?? false
        }

        hotkeyManager = HotkeyManager(
            onFullScreen: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    await self.appState.captureEngine.captureFullScreen(appState: self.appState)
                }
            },
            onArea: { [weak self] in
                guard let self else { return }
                self.appState.captureEngine.startAreaSelection(appState: self.appState)
            },
            onWindow: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    await self.appState.captureEngine.captureWindow(appState: self.appState)
                }
            },
            onCaptureText: { [weak self] in
                guard let self else { return }
                self.appState.captureEngine.startTextCapture(appState: self.appState)
            },
            onColorPicker: { [weak self] in
                guard let self else { return }
                self.appState.captureEngine.startColorPicker(appState: self.appState)
            },
            onMeasure: { [weak self] in
                guard let self else { return }
                self.appState.captureEngine.startMeasurement()
            },
            onHistory: { [weak self] in
                guard let self else { return }
                self.showHistoryBrowser()
            }
        )
    }

    func showOnboarding() {
        if appState.onboardingController == nil {
            appState.onboardingController = OnboardingWindowController(
                preferences: appState.preferences,
                launchAtLoginManager: appState.launchAtLoginManager
            )
        }
        appState.onboardingController?.showWindow()
    }

    private func showHistoryBrowser() {
        if appState.historyBrowserController == nil {
            appState.historyBrowserController = HistoryBrowserWindowController(
                historyManager: appState.historyManager,
                appState: appState
            )
        }
        appState.historyBrowserController?.showWindow()
    }

    private func checkScreenCapturePermission() {
        Task {
            do {
                _ = try await SCShareableContent.current
            } catch {
                let alert = NSAlert()
                alert.messageText = "Screen Capture Permission Required"
                alert.informativeText = "Mika+ScreenSnap needs screen capture permission to take screenshots. Please grant access in System Settings > Privacy & Security > Screen & System Audio Recording."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Quit")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        NSWorkspace.shared.open(url)
                    }
                } else {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

@main
struct MikaScreenSnapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private static let menubarIcon: NSImage = {
        if let url = Bundle.main.url(forResource: "MenubarIconTemplate@2x", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.size = NSSize(width: 18, height: 18)
            img.isTemplate = true
            return img
        }
        return NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Mika+ScreenSnap")!
    }()

    /// Checked when the menu is built, so the entry reflects the current answer.
    private var hasScreenRecordingAccess: Bool { CGPreflightScreenCaptureAccess() }

    var body: some Scene {
        MenuBarExtra {
            Button("About Mika+ScreenSnap") {
                if appDelegate.appState.aboutController == nil {
                    appDelegate.appState.aboutController = AboutWindowController()
                }
                appDelegate.appState.aboutController?.showWindow()
            }
            Button("Check for Updates...") {
                appDelegate.appState.sparkleUpdater.checkForUpdates()
            }
            .disabled(!appDelegate.appState.sparkleUpdater.canCheckForUpdates)
            if !hasScreenRecordingAccess {
                Button("\u{26A0} Screen Recording not granted") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            Divider()

            // Capture Section — disabled without the permission they all need, so the
            // path to granting it no longer runs through a failed attempt.
            Button("Capture Area  \u{2303}\u{21E7}\u{2318}4") {
                appDelegate.appState.captureEngine.startAreaSelection(appState: appDelegate.appState)
            }
            .disabled(!hasScreenRecordingAccess)
            Button("Capture Full Screen  \u{2303}\u{21E7}\u{2318}3") {
                Task {
                    await appDelegate.appState.captureEngine.captureFullScreen(appState: appDelegate.appState)
                }
            }
            .disabled(!hasScreenRecordingAccess)
            Button("Capture Window\u{2026}") {
                appDelegate.appState.captureEngine.startWindowSelection(appState: appDelegate.appState)
            }
            .disabled(!hasScreenRecordingAccess)
            Button("Capture Frontmost Window  \u{2303}\u{21E7}\u{2318}5") {
                Task {
                    await appDelegate.appState.captureEngine.captureWindow(appState: appDelegate.appState)
                }
            }
            .disabled(!hasScreenRecordingAccess)

            Divider()

            // Power Features Section
            Button("Capture Text  \u{21E7}\u{2318}6") {
                appDelegate.appState.captureEngine.startTextCapture(appState: appDelegate.appState)
            }
            .disabled(!hasScreenRecordingAccess)
            Button("Pick Color  \u{21E7}\u{2318}7") {
                appDelegate.appState.captureEngine.startColorPicker(appState: appDelegate.appState)
            }
            .disabled(!hasScreenRecordingAccess)
            Button("Measure  \u{21E7}\u{2318}8") {
                appDelegate.appState.captureEngine.startMeasurement()
            }
            .disabled(!hasScreenRecordingAccess)

            Divider()

            // Pinned Screenshots Submenu
            Menu("Pinned Screenshots") {
                if appDelegate.appState.pinnedPanels.isEmpty {
                    Text("No pinned screenshots")
                } else {
                    ForEach(0..<appDelegate.appState.pinnedPanels.count, id: \.self) { index in
                        Button("Pin \(index + 1)") {
                            appDelegate.appState.pinnedPanels[index].makeKeyAndOrderFront(nil)
                        }
                    }
                    Divider()
                    Button("Close All") {
                        PinnedScreenshotManager.unpinAll(appState: appDelegate.appState)
                    }
                }
            }

            // Color History Submenu
            Menu("Color History") {
                if appDelegate.appState.colorHistory.recentColors.isEmpty {
                    Text("No colors picked yet")
                } else {
                    ForEach(appDelegate.appState.colorHistory.recentColors, id: \.self) { hex in
                        Button {
                            ClipboardManager.copyToClipboard(text: hex, concealed: false)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(nsColor: ColorHistoryManager.colorFromHex(hex)))
                                    .frame(width: 12, height: 12)
                                Text(hex)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    Divider()
                    Button("Clear History") {
                        appDelegate.appState.colorHistory.clearHistory()
                    }
                }
            }

            // Palette — the shift-click target. It was persisted but never shown
            // anywhere, so shift-clicking was indistinguishable from a plain click.
            Menu("Colour Palette") {
                if appDelegate.appState.colorHistory.palette.isEmpty {
                    Text("Shift-click the picker to add a colour")
                } else {
                    ForEach(appDelegate.appState.colorHistory.palette, id: \.self) { hex in
                        Button {
                            ClipboardManager.copyToClipboard(text: hex, concealed: false)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(nsColor: ColorHistoryManager.colorFromHex(hex)))
                                    .frame(width: 12, height: 12)
                                Text(hex)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    Divider()
                    Button("Clear Palette") {
                        appDelegate.appState.colorHistory.clearPalette()
                    }
                }
            }

            // History Browser
            Button("Screenshot History  \u{21E7}\u{2318}H") {
                if appDelegate.appState.historyBrowserController == nil {
                    appDelegate.appState.historyBrowserController = HistoryBrowserWindowController(
                        historyManager: appDelegate.appState.historyManager,
                        appState: appDelegate.appState
                    )
                }
                appDelegate.appState.historyBrowserController?.showWindow()
            }

            Divider()

            Button("Preferences...") {
                if appDelegate.appState.preferencesController == nil {
                    appDelegate.appState.preferencesController = PreferencesWindowController(
                        preferences: appDelegate.appState.preferences,
                        launchAtLoginManager: appDelegate.appState.launchAtLoginManager,
                        sparkleUpdater: appDelegate.appState.sparkleUpdater,
                        historyManager: appDelegate.appState.historyManager,
                        hotkeyManager: appDelegate.hotkeyManager!,
                        appState: appDelegate.appState,
                        onShowOnboarding: { [weak appDelegate] in
                            appDelegate?.showOnboarding()
                        }
                    )
                }
                appDelegate.appState.preferencesController?.showWindow()
            }
            .keyboardShortcut(",")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(nsImage: Self.menubarIcon)
        }
    }
}
