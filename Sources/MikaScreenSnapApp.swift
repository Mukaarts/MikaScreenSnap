import SwiftUI
@preconcurrency import ScreenCaptureKit

@Observable
@MainActor
final class AppState {
    var captureEngine: CaptureEngine
    var lastCapture: NSImage?
    var annotationEditorController: AnnotationEditorWindowController?

    init() {
        self.captureEngine = CaptureEngine()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkScreenCapturePermission()

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
            }
        )
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
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
