// PermissionScreen.swift
// MikaScreenSnap
//
// Onboarding screen 2: Screen Recording permission request.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct PermissionScreen: View {
    let preferences: AppPreferences
    let onNext: () -> Void

    @State private var granted = CGPreflightScreenCaptureAccess()
    @State private var autoAdvanceTask: Task<Void, Never>?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.MikaPlus.tealPrimary)
            }

            Text("Screen Recording Permission")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Mika+ScreenSnap needs Screen Recording access to capture screenshots. Your data stays on your Mac — nothing is uploaded or shared.")
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            if !granted {
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
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

            if !granted {
                Button("Skip for now") {
                    preferences.permissionSkipped = true
                    onNext()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.MikaPlus.tealLight.opacity(0.5))
            }

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: granted)
        .onReceive(timer) { _ in
            let status = CGPreflightScreenCaptureAccess()
            if status && !granted {
                granted = true
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
}
