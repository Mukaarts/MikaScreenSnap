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
                                Toggle("Floating preview", isOn: Binding(
                                    get: { preferences.floatingPreviewEnabled },
                                    set: { preferences.floatingPreviewEnabled = $0 }
                                ))
                            } icon: {
                                Image(systemName: "pip")
                            }
                        }

                        if preferences.floatingPreviewEnabled {
                            Divider()
                            settingsRow {
                                Label("Dismiss after", systemImage: "timer")
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { preferences.previewDismissDuration },
                                    set: { preferences.previewDismissDuration = $0 }
                                )) {
                                    Text("3s").tag(3)
                                    Text("5s").tag(5)
                                    Text("10s").tag(10)
                                    Text("Never").tag(0)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
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
            preferences.saveLocation = url
        }
    }
}
