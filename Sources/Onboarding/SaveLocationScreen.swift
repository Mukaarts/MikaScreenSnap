// SaveLocationScreen.swift
// MikaScreenSnap
//
// Onboarding screen: pick the folder captures are written to. App Store build only.
// Swift 6.0 strict concurrency, macOS 14+

#if APPSTORE

import SwiftUI

/// Asks once for a folder to save screenshots in.
///
/// The sandbox has no path to `~/Pictures` that the app can take on its own. Rather than
/// writing into a container folder nobody can find, the user names a place — and then
/// finds their screenshots there, in the Finder, where they expect them.
///
/// Four states, per the design: nothing picked (Continue disabled) · picked · not writable
/// · gone. There is no loading state: the panel is modal and answers immediately.
struct SaveLocationScreen: View {
    let preferences: AppPreferences
    let onNext: () -> Void

    @State private var chosen: URL?
    @State private var problem: SaveLocationProblem?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: chosen == nil ? "folder.badge.questionmark" : "folder.fill.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(chosen == nil ? Color.MikaPlus.tealPrimary : Color.green)

            Text("Where should screenshots go?")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Pick a folder once and Mika+ScreenSnap saves every capture there. You can change it later in Settings.")
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            if let chosen {
                Text(chosen.lastPathComponent)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.MikaPlus.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.MikaPlus.tealPrimary.opacity(0.12), in: .rect(cornerRadius: 6))
            }

            Button(chosen == nil ? "Choose Folder…" : "Choose a Different Folder…") {
                chooseFolder()
            }
            .buttonStyle(.borderedProminent)

            if let problem {
                Text(problem.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Spacer()

            Button("Continue") { onNext() }
                .buttonStyle(.borderedProminent)
                .disabled(chosen == nil)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Use This Folder"
        panel.message = "Choose where Mika+ScreenSnap saves your screenshots."
        panel.directoryURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first

        // A cancelled panel leaves the screen as it was: Continue stays disabled and the
        // step is shown again, rather than letting setup finish with nowhere to write.
        guard panel.runModal() == .OK, let url = panel.url else { return }

        if SaveLocationStore.adopt(url, in: preferences) {
            chosen = url
            problem = nil
        } else {
            chosen = nil
            problem = .notWritable
        }
    }
}

#endif
