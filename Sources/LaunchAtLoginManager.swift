// LaunchAtLoginManager.swift
// MikaScreenSnap
//
// Manages Launch at Login via SMAppService (macOS 13+).
// System is source of truth — no UserDefaults needed.

import ServiceManagement

@MainActor
final class LaunchAtLoginManager {

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at Login failed: \(error.localizedDescription)")
        }
    }
}
