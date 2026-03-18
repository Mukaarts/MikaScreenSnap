// ShortcutsScreen.swift
// MikaScreenSnap
//
// Onboarding screen 3: Keyboard shortcuts overview and launch-at-login toggle.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct ShortcutsScreen: View {
    let launchAtLoginManager: LaunchAtLoginManager
    let preferences: AppPreferences
    let onDismiss: () -> Void

    @State private var launchAtLogin = true

    private let shortcuts: [(keys: String, label: String)] = [
        ("\u{2303}\u{21E7}\u{2318}3", "Fullscreen Capture"),
        ("\u{2303}\u{21E7}\u{2318}4", "Area Capture"),
        ("\u{2303}\u{21E7}\u{2318}5", "Window Capture"),
        ("\u{21E7}\u{2318}6", "OCR Text Extraction"),
        ("\u{21E7}\u{2318}7", "Color Picker"),
        ("\u{21E7}\u{2318}8", "Measure"),
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 8)

            Text("Keyboard Shortcuts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            VStack(spacing: 8) {
                ForEach(shortcuts, id: \.keys) { shortcut in
                    HStack {
                        Text(shortcut.keys)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color.MikaPlus.tealLight)
                            .frame(width: 100, alignment: .trailing)
                        Text(shortcut.label)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.MikaPlus.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            Toggle("Launch Mika+ScreenSnap at login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textPrimary)
                .padding(.horizontal, 40)

            Button {
                launchAtLoginManager.setEnabled(launchAtLogin)
                preferences.hasCompletedOnboarding = true
                onDismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 40)
                    .background(Color.MikaPlus.tealPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(height: 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
