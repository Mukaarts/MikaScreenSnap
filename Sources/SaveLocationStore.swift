// SaveLocationStore.swift
// MikaScreenSnap
//
// Resolves the folder captures are written to, on both editions.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

/// Why a save location is currently unusable.
enum SaveLocationProblem: Error, Equatable {
    /// No folder has been picked yet. App Store build only, before first-run setup.
    case notChosen
    /// The folder was renamed, deleted, or lives on a volume that is not mounted.
    case missing
    /// The folder exists but cannot be written to.
    case notWritable

    /// Plain-language text for the user. No paths: a folder name can carry as much
    /// information as a filename, and this string ends up in a toast.
    var message: String {
        switch self {
        case .notChosen:  return "Choose a folder to save screenshots to."
        case .missing:    return "The screenshot folder is no longer available. Choose it again."
        case .notWritable: return "The screenshot folder cannot be written to. Choose another one."
        }
    }
}

/// The folder captures are written to.
///
/// Two editions, two mechanisms. The direct build keeps a plain path and writes wherever it
/// likes. The App Store build only ever reaches a folder the user handed it, and holds that
/// permission as a security-scoped bookmark — a path alone survives a restart, the
/// permission to write there does not.
///
/// Access is opened around each write and closed again rather than held open for the
/// process lifetime: a permanently open scope outlives an unmounted volume and hides
/// exactly the failure the user needs to see.
@MainActor
enum SaveLocationStore {

    /// Whether this process actually runs inside a sandbox container.
    ///
    /// The App Store build is compiled with `APPSTORE` but is not always *running*
    /// sandboxed: a test process and a locally built binary are not. Security-scoped
    /// bookmarks only exist inside a container, so outside one the bookmark path is not
    /// merely unnecessary — it cannot work at all, and insisting on it would make the
    /// whole save path untestable.
    ///
    /// Verified rather than assumed: the variable is set to the container id under the
    /// sandbox and absent without it.
    static var isSandboxed: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }

    // MARK: - Resolving

    /// The folder to write to, or why there isn't one.
    static func resolve(_ preferences: AppPreferences) -> Result<URL, SaveLocationProblem> {
        #if APPSTORE
        // Outside a container there is no bookmark to resolve; fall through to the plain
        // path, which is what the direct build uses anyway.
        guard isSandboxed else { return resolvePlainPath(preferences) }

        guard let bookmark = preferences.saveLocationBookmark else { return .failure(.notChosen) }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return .failure(.missing)
        }

        // A stale bookmark still resolves — the folder moved or was renamed. Refreshing it
        // now keeps the permission alive; failing to refresh is not fatal for this write.
        if isStale, let refreshed = makeBookmark(for: url) {
            preferences.saveLocationBookmark = refreshed
        }

        guard accessing(url, { FileManager.default.fileExists(atPath: url.path) }) == true else {
            return .failure(.missing)
        }
        return .success(url)
        #else
        return resolvePlainPath(preferences)
        #endif
    }

    /// The direct build's answer, and the App Store build's answer outside a container.
    private static func resolvePlainPath(_ preferences: AppPreferences) -> Result<URL, SaveLocationProblem> {
        let url = preferences.saveLocation
        if !FileManager.default.fileExists(atPath: url.path) {
            guard (try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)) != nil
            else { return .failure(.missing) }
        }
        guard FileManager.default.isWritableFile(atPath: url.path) else { return .failure(.notWritable) }
        return .success(url)
    }

    // MARK: - Writing

    /// Runs `body` with the save folder available, without telling the user if it is not.
    ///
    /// For reads. "No folder chosen yet" is the normal state on a fresh App Store install,
    /// not a failure — and `loadHistory` runs at startup while `storageUsage` runs inside a
    /// SwiftUI body, so reporting here produced a notice on launch and another on every
    /// redraw of Preferences.
    static func readingSaveFolder<T>(
        _ preferences: AppPreferences,
        _ body: (URL) throws -> T
    ) -> T? {
        guard case .success(let url) = resolve(preferences) else { return nil }
        return accessing(url) { try? body(url) }
    }

    /// Runs `body` with the save folder available, or reports why it isn't.
    ///
    /// For writes and deletes — anything the user asked for and must be told about when it
    /// fails. On the App Store build this is what opens and closes the security scope; on
    /// the direct build it is a plain call.
    @discardableResult
    static func withSaveFolder<T>(
        _ preferences: AppPreferences,
        action: String,
        _ body: (URL) throws -> T
    ) -> T? {
        switch resolve(preferences) {
        case .failure(let problem):
            CaptureLog.report("\(action) failed: save location unavailable (\(problem))",
                              message: problem.message)
            return nil
        case .success(let url):
            return accessing(url) {
                do {
                    return try body(url)
                } catch {
                    CaptureLog.report(error, action: action)
                    return nil
                }
            }
        }
    }

    // MARK: - Choosing

    /// Records a folder the user picked. Returns false if it cannot be written to.
    static func adopt(_ url: URL, in preferences: AppPreferences) -> Bool {
        guard FileManager.default.isWritableFile(atPath: url.path) else { return false }
        #if APPSTORE
        if isSandboxed {
            guard let bookmark = makeBookmark(for: url) else { return false }
            preferences.saveLocationBookmark = bookmark
        }
        #endif
        preferences.saveLocation = url
        return true
    }

    // MARK: - Helpers

    /// Opens the security scope for the duration of `body`, on the App Store build only.
    private static func accessing<T>(_ url: URL, _ body: () -> T) -> T {
        #if APPSTORE
        guard isSandboxed else { return body() }
        let opened = url.startAccessingSecurityScopedResource()
        defer { if opened { url.stopAccessingSecurityScopedResource() } }
        return body()
        #else
        return body()
        #endif
    }

    private static func makeBookmark(for url: URL) -> Data? {
        #if APPSTORE
        return try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #else
        return nil
        #endif
    }
}
