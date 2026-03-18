// PreferencesWindowController.swift
// MikaScreenSnap
//
// Native macOS preferences window controller.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

@MainActor
final class PreferencesWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let preferences: AppPreferences
    private let launchAtLoginManager: LaunchAtLoginManager
    private let sparkleUpdater: SparkleUpdater
    private let historyManager: ScreenshotHistoryManager
    private let hotkeyManager: HotkeyManager
    private let onShowOnboarding: () -> Void

    init(
        preferences: AppPreferences,
        launchAtLoginManager: LaunchAtLoginManager,
        sparkleUpdater: SparkleUpdater,
        historyManager: ScreenshotHistoryManager,
        hotkeyManager: HotkeyManager,
        onShowOnboarding: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.launchAtLoginManager = launchAtLoginManager
        self.sparkleUpdater = sparkleUpdater
        self.historyManager = historyManager
        self.hotkeyManager = hotkeyManager
        self.onShowOnboarding = onShowOnboarding
    }

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Mika+ScreenSnap Settings"
        window.isReleasedWhenClosed = false
        window.delegate = self

        let contentView = PreferencesContainerView(
            preferences: preferences,
            launchAtLoginManager: launchAtLoginManager,
            sparkleUpdater: sparkleUpdater,
            historyManager: historyManager,
            hotkeyManager: hotkeyManager,
            onShowOnboarding: onShowOnboarding
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
