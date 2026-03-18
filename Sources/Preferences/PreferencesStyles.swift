// PreferencesStyles.swift
// MikaScreenSnap
//
// Shared types for the preferences window (native macOS style).
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

// MARK: - PreferencesTab

enum PreferencesTab: String, CaseIterable, Identifiable, Sendable {
    case general
    case shortcuts
    case annotation
    case advanced

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .general:    return "gearshape"
        case .shortcuts:  return "keyboard"
        case .annotation: return "pencil.and.outline"
        case .advanced:   return "slider.horizontal.3"
        }
    }

    var label: String {
        switch self {
        case .general:    return "General"
        case .shortcuts:  return "Shortcuts"
        case .annotation: return "Annotation"
        case .advanced:   return "Advanced"
        }
    }
}
