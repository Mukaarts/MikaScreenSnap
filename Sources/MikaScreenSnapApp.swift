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

    init() {
        let prefs = AppPreferences()
        self.preferences = prefs
        self.captureEngine = CaptureEngine()
        self.historyManager = ScreenshotHistoryManager(preferences: prefs)
        self.colorHistory = ColorHistoryManager()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkScreenCapturePermission()

        // Restore pinned screenshots
        PinnedScreenshotManager.restorePins(appState: appState)

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
                self.appState.captureEngine.startMeasurement(appState: self.appState)
            },
            onHistory: { [weak self] in
                guard let self else { return }
                self.showHistoryBrowser()
            }
        )
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

    var body: some Scene {
        MenuBarExtra("Mika+ScreenSnap", systemImage: "camera.viewfinder") {
            // Capture Section
            Button("Capture Area  \u{2303}\u{21E7}\u{2318}4") {
                appDelegate.appState.captureEngine.startAreaSelection(appState: appDelegate.appState)
            }
            Button("Capture Full Screen  \u{2303}\u{21E7}\u{2318}3") {
                Task {
                    await appDelegate.appState.captureEngine.captureFullScreen(appState: appDelegate.appState)
                }
            }
            Button("Capture Window  \u{2303}\u{21E7}\u{2318}5") {
                Task {
                    await appDelegate.appState.captureEngine.captureWindow(appState: appDelegate.appState)
                }
            }

            Divider()

            // Power Features Section
            Button("Capture Text  \u{21E7}\u{2318}6") {
                appDelegate.appState.captureEngine.startTextCapture(appState: appDelegate.appState)
            }
            Button("Pick Color  \u{21E7}\u{2318}7") {
                appDelegate.appState.captureEngine.startColorPicker(appState: appDelegate.appState)
            }
            Button("Measure  \u{21E7}\u{2318}8") {
                appDelegate.appState.captureEngine.startMeasurement(appState: appDelegate.appState)
            }

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
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(hex, forType: .string)
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
                        preferences: appDelegate.appState.preferences
                    )
                }
                appDelegate.appState.preferencesController?.showWindow()
            }
            .keyboardShortcut(",")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
