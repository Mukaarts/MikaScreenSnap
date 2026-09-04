// GeneralTabView.swift
// MikaScreenSnap
//
// General preferences: file output and capture behavior.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct GeneralTabView: View {
    let preferences: AppPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title2.bold())

            // File Output
            VStack(alignment: .leading, spacing: 0) {
                Text("File Output")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        settingsRow {
                            Label("Save to", systemImage: "folder")
                            Spacer()
                            Text(preferences.saveLocation.lastPathComponent)
                                .foregroundStyle(.secondary)
                            Button("Change...") {
                                chooseFolder()
                            }
                        }

                        Divider()

                        settingsRow {
                            Label("Format", systemImage: "doc.richtext")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { preferences.imageFormat },
                                set: { preferences.imageFormat = $0 }
                            )) {
                                ForEach(ImageFormat.allCases, id: \.self) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 130)
                        }

                        if preferences.imageFormat == .jpeg {
                            Divider()
                            settingsRow {
                                Label("Quality", systemImage: "slider.horizontal.below.rectangle")
                                Spacer()
                                Slider(value: Binding(
                                    get: { preferences.jpegQuality },
                                    set: { preferences.jpegQuality = $0 }
                                ), in: 0.7...1.0, step: 0.05)
                                .frame(width: 120)
                                Text("\(Int(preferences.jpegQuality * 100))%")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .frame(width: 36, alignment: .trailing)
                            }
                        }
                    }
                }
            }

            // Capture Behavior
            VStack(alignment: .leading, spacing: 0) {
                Text("Capture Behavior")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        settingsRow {
                            Label {
                                Toggle("Capture sound", isOn: Binding(
                                    get: { preferences.captureSoundEnabled },
                                    set: { preferences.captureSoundEnabled = $0 }
                                ))
                            } icon: {
                                Image(systemName: "speaker.wave.2")
                            }
                        }

                        Divider()

                        settingsRow {
                            Label {
                                Toggle("Auto-save screenshots", isOn: Binding(
                                    get: { preferences.autoSaveEnabled },
                                    set: { preferences.autoSaveEnabled = $0 }
                                ))
                            } icon: {
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                    }
                }
            }

            // Privacy
            ExcludedAppsSection(preferences: preferences)
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            // Goes through the store so the App Store build records a bookmark; without it
            // the path survives the restart but the permission to write there does not.
            if !SaveLocationStore.adopt(url, in: preferences) {
                CaptureLog.report("Chosen save folder is not writable",
                                  message: SaveLocationProblem.notWritable.message)
            }
        }
    }
}

// MARK: - Excluded Apps

/// Lets the user pick applications whose windows are never captured — the on-screen
/// keyboard and similar overlays that would otherwise be baked into every screenshot.
struct ExcludedAppsSection: View {
    let preferences: AppPreferences

    @State private var manager = ExcludedAppsManager()
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Privacy")
                .font(.headline)
                .padding(.bottom, 6)

            GroupBox {
                VStack(spacing: 0) {
                    HStack {
                        Label("Exclude apps from capture", systemImage: "eye.slash")
                        Spacer()
                        Text(excludedSummary)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Button("Choose...") {
                            showPicker = true
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            ExcludedAppsPicker(preferences: preferences, manager: manager)
        }
    }

    private var excludedSummary: String {
        let count = preferences.excludedBundleIdentifiers.count
        switch count {
        case 0:  return "None"
        case 1:  return "1 app"
        default: return "\(count) apps"
        }
    }
}

private struct ExcludedAppsPicker: View {
    let preferences: AppPreferences
    let manager: ExcludedAppsManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exclude Apps from Capture")
                .font(.headline)

            Text("Windows of the selected apps are left out of every screenshot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if manager.isLoading && manager.apps.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.apps.isEmpty {
                Text("No capturable apps found. Grant Screen Recording permission and try again.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(manager.apps) { app in
                    Toggle(isOn: binding(for: app.bundleIdentifier)) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(app.name)
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.inset)
                .alternatingRowBackgrounds()
            }

            HStack {
                Button("Refresh") {
                    Task { await manager.refresh(selected: preferences.excludedBundleIdentifiers) }
                }
                Button("Add App...") {
                    addApplication()
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420, height: 400)
        .task {
            await manager.refresh(selected: preferences.excludedBundleIdentifiers)
        }
    }

    /// Lets the user exclude an application that is not currently running.
    private func addApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Exclude"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            if let bundleID = await manager.add(
                applicationAt: url, selected: preferences.excludedBundleIdentifiers
            ) {
                preferences.excludedBundleIdentifiers.insert(bundleID)
            }
        }
    }

    private func binding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding(
            get: { preferences.excludedBundleIdentifiers.contains(bundleIdentifier) },
            set: { isExcluded in
                if isExcluded {
                    preferences.excludedBundleIdentifiers.insert(bundleIdentifier)
                } else {
                    preferences.excludedBundleIdentifiers.remove(bundleIdentifier)
                }
            }
        )
    }
}
