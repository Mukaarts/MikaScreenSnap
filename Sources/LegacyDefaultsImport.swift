// LegacyDefaultsImport.swift
// MikaScreenSnap
//
// One-time carry-over from the pre-3.6 bundle identifier. Direct build only.
// Swift 6.0 strict concurrency, macOS 14+

#if !APPSTORE

import Foundation

/// Carries settings over from the bundle identifier the app used before 3.6.
///
/// macOS keys `UserDefaults` off the bundle identifier, so renaming it leaves every
/// existing install looking brand new: no hotkeys, no exclusion list, no drawing defaults.
/// This reads the old domain once and copies what it finds.
///
/// **Direct build only, and that is measured rather than assumed:** a sandboxed process
/// cannot read another bundle's preferences domain at all — a probe returned nothing under
/// the sandbox and the full value without it. The App Store build therefore does not
/// contain this file, and does not ask about an import it could not perform.
@MainActor
enum LegacyDefaultsImport {

    /// The identifier used up to and including 3.5.0.
    static let legacyDomain = "com.mika.mikaplusscreensnap"

    /// Marks the import as done. Deliberately **not** in `ownedDefaultsKeys`: resetting
    /// preferences is a request to start clean, not to pull the old settings back in.
    /// A test asserts this, so adding the key "for completeness" fails loudly.
    static let completionKey = "legacyDefaultsImported"

    /// Keys that must not be carried over, and why.
    ///
    /// - `hasCompletedOnboarding`: the capture permission is tied to the bundle identifier
    ///   too and is gone with it. Carrying this over would mark setup complete for an app
    ///   that cannot capture anything.
    /// - `saveLocationBookmark`: App Store build only, and a bookmark from another bundle
    ///   would not resolve anyway.
    private static let excluded: Set<String> = ["hasCompletedOnboarding", "saveLocationBookmark"]

    /// Copies the old settings across, once.
    ///
    /// - Returns: the number of values carried over, or `nil` if nothing was done.
    /// - Parameters:
    ///   - domain: the old identifier. Injectable so the carry-over itself can be tested,
    ///     not just its guard clauses — an untested import is how a silent data loss ships.
    ///   - defaults: where to write. Injectable for the same reason.
    @discardableResult
    static func runIfNeeded(from domain: String = legacyDomain,
                            into defaults: UserDefaults = .standard) -> Int? {
        guard !defaults.bool(forKey: completionKey) else { return nil }
        guard Bundle.main.bundleIdentifier != domain else { return nil }
        guard let legacy = UserDefaults(suiteName: domain) else { return nil }

        var carried = 0
        for key in AppPreferences.ownedDefaultsKeys where !excluded.contains(key) {
            // Only copy what the old install actually set. A missing key must stay missing
            // so the current defaults apply, rather than being overwritten with nil.
            guard let value = legacy.object(forKey: key) else { continue }
            // Never overwrite something the new install already has: the user may have
            // launched once and changed a setting before this ever ran.
            guard defaults.object(forKey: key) == nil else { continue }
            defaults.set(value, forKey: key)
            carried += 1
        }

        // Marked done even when nothing was found — a fresh install has no old domain, and
        // retrying on every launch would be pointless work.
        defaults.set(true, forKey: completionKey)
        return carried
    }
}

#endif
