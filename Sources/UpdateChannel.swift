// UpdateChannel.swift
// MikaScreenSnap
//
// The one place where the two editions differ at runtime.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

/// How this build of the app gets updated.
///
/// The direct-download build checks an appcast through Sparkle; the App Store build does
/// not update itself at all. Rather than scattering `#if APPSTORE` across the menu bar and
/// three Preferences files, the difference lives here — which also makes it testable.
@MainActor
protocol UpdateChannel: AnyObject {
    /// Whether the UI should offer update controls at all.
    ///
    /// False in the App Store build: an app that ships its own updater is rejected, and a
    /// disabled button would just raise a question it cannot answer.
    var showsUpdateControls: Bool { get }

    /// Shown in place of the controls when `showsUpdateControls` is false.
    var unavailableExplanation: String? { get }

    var canCheckForUpdates: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    var lastUpdateCheckDate: Date? { get }

    /// Asked before an update relaunches the app, so an editor holding unsaved
    /// annotations can stop it from throwing that work away.
    var hasUnsavedWork: (@MainActor () -> Bool)? { get set }

    func checkForUpdates()
}

#if APPSTORE

/// The App Store build's update channel: there isn't one.
///
/// The App Store installs updates itself. Everything here is inert by design, not
/// unimplemented.
@MainActor
final class AppStoreUpdateChannel: UpdateChannel {
    var showsUpdateControls: Bool { false }
    var unavailableExplanation: String? { "Updates are delivered through the App Store." }
    var canCheckForUpdates: Bool { false }
    var automaticallyChecksForUpdates: Bool {
        get { false }
        set { _ = newValue }
    }
    var lastUpdateCheckDate: Date? { nil }
    var hasUnsavedWork: (@MainActor () -> Bool)?
    func checkForUpdates() {}
}

#else

/// The direct-download build's update channel: the existing Sparkle wrapper, unchanged
/// behind a protocol.
@MainActor
final class SparkleUpdateChannel: UpdateChannel {
    private let updater = SparkleUpdater()

    var showsUpdateControls: Bool { true }
    var unavailableExplanation: String? { nil }
    var canCheckForUpdates: Bool { updater.canCheckForUpdates }

    var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set { updater.automaticallyChecksForUpdates = newValue }
    }

    var lastUpdateCheckDate: Date? { updater.lastUpdateCheckDate }

    var hasUnsavedWork: (@MainActor () -> Bool)? {
        get { updater.hasUnsavedWork }
        set { updater.hasUnsavedWork = newValue }
    }

    func checkForUpdates() { updater.checkForUpdates() }
}

#endif

/// The channel this build uses. The single switch between the two editions.
@MainActor
func makeUpdateChannel() -> any UpdateChannel {
    #if APPSTORE
    AppStoreUpdateChannel()
    #else
    SparkleUpdateChannel()
    #endif
}
