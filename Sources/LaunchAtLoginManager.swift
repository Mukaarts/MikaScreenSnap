// LaunchAtLoginManager.swift
// MikaScreenSnap
//
// Manages Launch at Login via SMAppService (macOS 13+).
// System is source of truth — no UserDefaults needed.

import ServiceManagement

@Observable
@MainActor
final class LaunchAtLoginManager {

    /// Bumped whenever the registration changes, so SwiftUI re-reads `isEnabled`.
    ///
    /// Without it a failed registration left the toggle showing the state the user asked
    /// for rather than the one the system actually holds.
    private var revision = 0

    var isEnabled: Bool {
        _ = revision
        return SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        defer { revision += 1 }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            CaptureLog.report(error, action: enabled ? "Enabling launch at login"
                                                     : "Disabling launch at login")
        }
    }
}
