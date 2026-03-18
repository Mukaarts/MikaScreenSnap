// AdvancedTabView.swift
// MikaScreenSnap
//
// Advanced preferences: system, storage, and about.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct AdvancedTabView: View {
    let preferences: AppPreferences
    let launchAtLoginManager: LaunchAtLoginManager
    let sparkleUpdater: SparkleUpdater
    let historyManager: ScreenshotHistoryManager
    let hotkeyManager: HotkeyManager
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

                        settingsRow {
                            Label {
                                Toggle("Automatic updates", isOn: Binding(
                                    get: { sparkleUpdater.automaticallyChecksForUpdates },
                                    set: { sparkleUpdater.automaticallyChecksForUpdates = $0 }
                                ))
                            } icon: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }

                        Divider()

                        settingsRow {
                            Label("Check for Updates", systemImage: "arrow.down.circle")
                            Spacer()
                            if let lastCheck = sparkleUpdater.lastUpdateCheckDate {
                                Text("\(lastCheck, style: .relative) ago")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            Button("Check Now") {
                                sparkleUpdater.checkForUpdates()
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

                        settingsRow {
                            Spacer()
                            Button {
                                NSWorkspace.shared.open(preferences.saveLocation)
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
                preferences.resetAllPreferences()
                var defaults: [HotkeyAction: HotkeyBinding] = [:]
                for action in HotkeyAction.allCases {
                    defaults[action] = action.defaultBinding
                }
                hotkeyManager.reRegisterAll(bindings: defaults)
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
