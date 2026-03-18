// OnboardingWindow.swift
// MikaScreenSnap
//
// Window controller for the first-launch onboarding flow.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let preferences: AppPreferences
    private let launchAtLoginManager: LaunchAtLoginManager

    init(preferences: AppPreferences, launchAtLoginManager: LaunchAtLoginManager) {
        self.preferences = preferences
        self.launchAtLoginManager = launchAtLoginManager
    }

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self

        let contentView = OnboardingView(
            preferences: preferences,
            launchAtLoginManager: launchAtLoginManager,
            onDismiss: { [weak self] in self?.close() }
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        preferences.hasCompletedOnboarding = true
        window = nil
    }
}
