// SparkleUpdater.swift
// MikaScreenSnap
//
// Sparkle auto-update wrapper for checking and installing updates.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
@preconcurrency import Sparkle

@MainActor
final class SparkleUpdater: NSObject {
    private var updaterController: SPUStandardUpdaterController!

    /// Asked before Sparkle relaunches, so an editor holding unsaved annotations can stop
    /// an update from throwing that work away.
    var hasUnsavedWork: (@MainActor () -> Bool)?

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    /// True when running under XCTest, where there is no real app bundle to update.
    ///
    /// Starting the updater there blocks: Sparkle looks for a bundle to check and never
    /// gets an answer.
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    override init() {
        super.init()
        // A delegate is passed now: without one the app learned nothing about an update
        // and could not defer a relaunch.
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: !SparkleUpdater.isRunningTests,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
    }

    var lastUpdateCheckDate: Date? {
        updaterController.updater.lastUpdateCheckDate
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

extension SparkleUpdater: SPUUpdaterDelegate {
    nonisolated func updater(
        _ updater: SPUUpdater,
        shouldPostponeRelaunchForUpdate item: SUAppcastItem,
        untilInvokingBlock installHandler: @escaping () -> Void
    ) -> Bool {
        let version = item.displayVersionString
        // Returning true without ever invoking the handler postpones the install; Sparkle
        // offers it again on the next launch. The handler is deliberately left untouched
        // so it never crosses an isolation boundary.
        return MainActor.assumeIsolated { () -> Bool in
            guard hasUnsavedWork?() == true else { return false }

            let alert = NSAlert()
            alert.messageText = "Finish editing before updating?"
            alert.informativeText = """
                The annotation editor has unsaved changes. Installing version \(version) now \
                would close it and discard them.
                """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Later")
            alert.addButton(withTitle: "Install Anyway")

            return alert.runModal() == .alertFirstButtonReturn
        }
    }

    nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        MainActor.assumeIsolated {
            // Silent by default before — a failed check left no trace anywhere.
            CaptureLog.engine.error("Update check failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
