// CaptureLog.swift
// MikaScreenSnap
//
// Unified logging and user-facing reporting for capture failures.
// Swift 6.0 strict concurrency, macOS 14+

import Foundation
import OSLog
@preconcurrency import ScreenCaptureKit

/// Capture failures used to end in `print()`, which goes nowhere in an LSUIElement
/// bundle launched from Finder. Everything routes through here instead, so the same
/// failure is both greppable in Console.app and visible to the user.
enum CaptureLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.mika.mikaplusscreensnap"

    static let engine = Logger(subsystem: subsystem, category: "capture")
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")

    /// Logs a failure and shows the user a short, plain-language toast.
    /// - Parameter action: What was attempted, capitalised — e.g. "Window capture".
    @MainActor
    static func report(_ error: Error, action: String) {
        engine.error("\(action) failed: \(error.localizedDescription, privacy: .public)")
        StatusToast.show(message(for: error, action: action))
    }

    /// Logs a failure that has no underlying `Error` and shows the given message.
    @MainActor
    static func report(_ reason: String, message: String) {
        engine.error("\(reason, privacy: .public)")
        StatusToast.show(message)
    }

    private static func message(for error: Error, action: String) -> String {
        let nsError = error as NSError
        guard nsError.domain == SCStreamErrorDomain else { return "\(action) failed" }

        // Raw values from SCError.h — spelled out so a missing Swift overlay
        // enum on a future SDK cannot break the build.
        switch nsError.code {
        case -3801:             // userDeclined
            return "Screen Recording permission required"
        case -3813, -3814, -3815: // noWindowList, noDisplayList, noCaptureSource
            return "Nothing available to capture"
        default:
            return "\(action) failed (\(nsError.code))"
        }
    }
}
