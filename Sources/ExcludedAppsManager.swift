// ExcludedAppsManager.swift
// MikaScreenSnap
//
// Lists the capturable running applications so the user can exclude them from screenshots.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
@preconcurrency import ScreenCaptureKit

@Observable
@MainActor
final class ExcludedAppsManager {
    struct CapturableApp: Identifiable, Hashable {
        let bundleIdentifier: String
        let name: String

        var id: String { bundleIdentifier }
    }

    private(set) var apps: [CapturableApp] = []
    private(set) var isLoading = false

    /// Reloads the list of shareable applications.
    ///
    /// Already excluded bundle identifiers are merged in even when the app is not running,
    /// so an existing selection never silently disappears from the UI.
    func refresh(selected: Set<String>) async {
        isLoading = true
        defer { isLoading = false }

        var byBundleID: [String: CapturableApp] = [:]

        if let content = try? await SCShareableContent.current {
            let ownPID = ProcessInfo.processInfo.processIdentifier
            for app in content.applications where app.processID != ownPID {
                let bundleID = app.bundleIdentifier
                let name = app.applicationName
                guard !bundleID.isEmpty, !name.isEmpty else { continue }
                byBundleID[bundleID] = CapturableApp(bundleIdentifier: bundleID, name: name)
            }
        }

        for bundleID in selected where byBundleID[bundleID] == nil {
            byBundleID[bundleID] = CapturableApp(
                bundleIdentifier: bundleID,
                name: ExcludedAppsManager.displayName(for: bundleID)
            )
        }

        apps = byBundleID.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// Best-effort name for an app that is currently not running.
    private static func displayName(for bundleIdentifier: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        else { return bundleIdentifier }
        return FileManager.default.displayName(atPath: url.path)
    }
}
