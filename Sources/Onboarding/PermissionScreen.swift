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
                    requestAccess()
                } label: {
                    Text("Grant Access")
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

    /// Asks the system for the permission, then opens Settings.
    ///
    /// Only ever preflighting the permission meant the system never listed the app, so a
    /// user following this screen could arrive at a Screen Recording list the app was not
    /// in yet. `CGRequestScreenCaptureAccess` registers it and shows the system prompt;
    /// Settings is opened afterwards because macOS does not re-prompt once the answer has
    /// been given.
    private func requestAccess() {
        Task {
            let granted = await Task.detached { CGRequestScreenCaptureAccess() }.value
            if granted {
                self.granted = true
                return
            }
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
