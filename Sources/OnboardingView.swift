// OnboardingView.swift
// MikaScreenSnap
//
// First-launch onboarding flow with welcome, permissions, and shortcuts screens.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI
import ServiceManagement

@MainActor
struct OnboardingView: View {
    let preferences: AppPreferences
    let onDismiss: () -> Void

    @State private var currentPage = 0
    @State private var permissionGranted = CGPreflightScreenCaptureAccess()
    @State private var launchAtLogin = true

    private var totalPages: Int {
        permissionGranted ? 2 : 3
    }

    private var pageIndex: Int {
        if permissionGranted && currentPage >= 1 {
            // Skip permissions page: page 1 maps to shortcuts (index 2)
            return currentPage == 1 ? 2 : currentPage
        }
        return currentPage
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                WelcomePageView(onNext: advanceFromWelcome)
                    .tag(0)

                if !permissionGranted {
                    PermissionsPageView(
                        permissionGranted: $permissionGranted,
                        onNext: { withAnimation { currentPage = permissionGranted ? 1 : 2 } },
                        onSkip: {
                            preferences.permissionSkipped = true
                            withAnimation { currentPage = 2 }
                        }
                    )
                    .tag(1)

                    ShortcutsPageView(launchAtLogin: $launchAtLogin, onDone: finishOnboarding)
                        .tag(2)
                } else {
                    ShortcutsPageView(launchAtLogin: $launchAtLogin, onDone: finishOnboarding)
                        .tag(1)
                }
            }
            .tabViewStyle(.automatic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Dot indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.MikaPlus.tealPrimary : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.MikaPlus.darkBgDeep, Color.MikaPlus.darkBg],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private func advanceFromWelcome() {
        withAnimation {
            if permissionGranted {
                currentPage = 1
            } else {
                currentPage = 1
            }
        }
    }

    private func finishOnboarding() {
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        }
        preferences.launchAtLogin = launchAtLogin
        preferences.hasCompletedOnboarding = true
        onDismiss()
    }
}

// MARK: - Welcome Page

@MainActor
private struct WelcomePageView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 192, height: 192)
            } else {
                Image(systemName: "camera.viewfinder")
                    .resizable()
                    .frame(width: 192, height: 192)
                    .foregroundStyle(Color.MikaPlus.tealPrimary)
            }

            Text("Welcome to Mika+ScreenSnap")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Screenshot. Annotate. Ship.")
                .font(.system(size: 14))
                .foregroundStyle(Color.MikaPlus.tealLight)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 40)
                    .background(Color.MikaPlus.tealPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Permissions Page

@MainActor
private struct PermissionsPageView: View {
    @Binding var permissionGranted: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var autoAdvanceTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if permissionGranted {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Color.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "lock.shield")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Color.MikaPlus.tealPrimary)
            }

            Text("Screen Recording Permission")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Mika+ScreenSnap needs screen recording access to capture screenshots. Your privacy is respected — we never record audio or video.")
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if permissionGranted {
                Text("Permission granted!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.green)
            } else {
                Button(action: openSystemSettings) {
                    Text("Open System Settings")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 40)
                        .background(Color.MikaPlus.tealPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if !permissionGranted {
                Button("Skip for now") {
                    onSkip()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.MikaPlus.tealLight.opacity(0.5))
            }

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if !permissionGranted && CGPreflightScreenCaptureAccess() {
                withAnimation {
                    permissionGranted = true
                }
                autoAdvanceTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    if !Task.isCancelled {
                        onNext()
                    }
                }
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Shortcuts Page

@MainActor
private struct ShortcutsPageView: View {
    @Binding var launchAtLogin: Bool
    let onDone: () -> Void

    private let shortcuts: [(keys: String, label: String)] = [
        ("\u{2303}\u{21E7}\u{2318}3", "Fullscreen"),
        ("\u{2303}\u{21E7}\u{2318}4", "Area"),
        ("\u{2303}\u{21E7}\u{2318}5", "Window"),
        ("\u{21E7}\u{2318}6", "OCR"),
        ("\u{21E7}\u{2318}7", "Color Picker"),
        ("\u{21E7}\u{2318}8", "Measure"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 20)

            Text("Keyboard Shortcuts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Use these global hotkeys from anywhere.")
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)

            VStack(spacing: 8) {
                ForEach(shortcuts, id: \.keys) { shortcut in
                    ShortcutCardView(keys: shortcut.keys, label: shortcut.label)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 12)

            Toggle("Launch Mika+ScreenSnap at login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 40)
                    .background(Color.MikaPlus.tealPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@MainActor
private struct ShortcutCardView: View {
    let keys: String
    let label: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color.MikaPlus.tealLight)
                .frame(width: 100, alignment: .trailing)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
