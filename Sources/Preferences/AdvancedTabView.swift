// AdvancedTabView.swift
// MikaScreenSnap
//
// Advanced preferences: system, storage, and about.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct AdvancedTabView: View {
    let preferences: AppPreferences
    let launchAtLoginManager: LaunchAtLoginManager
    let updateChannel: any UpdateChannel
    let historyManager: ScreenshotHistoryManager
    let hotkeyManager: HotkeyManager
    let appState: AppState
    let onShowOnboarding: () -> Void

    @State private var showClearConfirmation = false
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced")
                .font(.title2.bold())

            // System
            VStack(alignment: .leading, spacing: 0) {
                Text("System")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        settingsRow {
                            Label {
                                Toggle("Launch at Login", isOn: Binding(
                                    get: { launchAtLoginManager.isEnabled },
                                    set: { launchAtLoginManager.setEnabled($0) }
                                ))
                            } icon: {
                                Image(systemName: "person.crop.circle")
                            }
                        }

                        Divider()

                        // The App Store build has no updater of its own — a disabled
                        // toggle would raise a question it cannot answer, so the controls
                        // give way to a sentence that does.
                        if updateChannel.showsUpdateControls {
                            settingsRow {
                                Label {
                                    Toggle("Automatic updates", isOn: Binding(
                                        get: { updateChannel.automaticallyChecksForUpdates },
                                        set: { updateChannel.automaticallyChecksForUpdates = $0 }
                                    ))
                                } icon: {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                            }

                            Divider()

                            settingsRow {
                                Label("Check for Updates", systemImage: "arrow.down.circle")
                                Spacer()
                                if let lastCheck = updateChannel.lastUpdateCheckDate {
                                    Text("\(lastCheck, style: .relative) ago")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                Button("Check Now") {
                                    updateChannel.checkForUpdates()
                                }
                            }
                        } else if let explanation = updateChannel.unavailableExplanation {
                            settingsRow {
                                Label(explanation, systemImage: "arrow.down.circle")
                                    .foregroundStyle(Color.MikaPlus.textSecondary)
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Storage
            VStack(alignment: .leading, spacing: 0) {
                Text("Storage")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        settingsRow {
                            let count = historyManager.items.count
                            let size = historyManager.storageUsage()
                            Label("\(count) screenshot\(count == 1 ? "" : "s")", systemImage: "photo.on.rectangle")
                            Spacer()
                            Text(ScreenshotHistoryManager.formatBytes(size))
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // Pinned screenshots live in Application Support and used to be
                        // invisible here — and unreachable by Clear History.
                        settingsRow {
                            let pinnedSize = PinnedScreenshotManager.storageUsage()
                            Label("Pinned screenshots", systemImage: "pin")
                            Spacer()
                            Text(ScreenshotHistoryManager.formatBytes(pinnedSize))
                                .foregroundStyle(.secondary)
                            Button("Clear") {
                                PinnedScreenshotManager.clearAll(appState: appState)
                            }
                            .disabled(PinnedScreenshotManager.storageUsage() == 0)
                        }

                        Divider()

                        settingsRow {
                            Spacer()
                            Button {
                                // Must be the folder actually written to, not the stored
                                // path: after a reset those differ, and the button would
                                // open an empty ~/Pictures the App Store build never used.
                                switch SaveLocationStore.resolve(preferences) {
                                case .success(let folder):
                                    NSWorkspace.shared.open(folder)
                                case .failure(let problem):
                                    CaptureLog.report("Open Folder: \(problem)",
                                                      message: problem.message)
                                }
                            } label: {
                                Label("Open Folder", systemImage: "folder")
                            }
                            Button(role: .destructive) {
                                showClearConfirmation = true
                            } label: {
                                Label("Clear History", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // About
            VStack(alignment: .leading, spacing: 0) {
                Text("About")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        settingsRow {
                            Label("Onboarding", systemImage: "hand.wave")
                            Spacer()
                            Button("Show Again") {
                                onShowOnboarding()
                            }
                        }

                        Divider()

                        settingsRow {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                            Spacer()
                            Button(role: .destructive) {
                                showResetConfirmation = true
                            } label: {
                                Text("Reset All Preferences...")
                            }
                        }

                        Divider()

                        settingsRow {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                               let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                                Text("v\(version) (\(build))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .alert("Clear History", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                historyManager.clearAll()
            }
        } message: {
            Text("This will permanently delete all saved screenshots and thumbnails.")
        }
        .alert("Reset All Preferences", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                let needsSetupAgain = preferences.resetAllPreferences()
                var defaults: [HotkeyAction: HotkeyBinding] = [:]
                for action in HotkeyAction.allCases {
                    defaults[action] = action.defaultBinding
                }
                hotkeyManager.reRegisterAll(bindings: defaults)
                // Without this the App Store build sits there with no save location until
                // the next launch, telling the user to choose a folder with no way to.
                if needsSetupAgain { onShowOnboarding() }
            }
        } message: {
            Text("This will reset all settings to their defaults. This action cannot be undone.")
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
