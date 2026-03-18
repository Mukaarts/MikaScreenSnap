// PreferencesView.swift
// MikaScreenSnap
//
// Preferences window: auto-save toggle, folder picker, image format selection.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

@MainActor
final class PreferencesWindowController {
    private var window: NSWindow?
    private let preferences: AppPreferences
    private let onShowOnboarding: () -> Void

    init(preferences: AppPreferences, onShowOnboarding: @escaping () -> Void) {
        self.preferences = preferences
        self.onShowOnboarding = onShowOnboarding
    }

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        NSApp.setActivationPolicy(.regular)

        let contentView = PreferencesView(preferences: preferences, onShowOnboarding: onShowOnboarding)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}

struct PreferencesView: View {
    let preferences: AppPreferences
    let onShowOnboarding: () -> Void

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { preferences.launchAtLogin },
                    set: { preferences.launchAtLogin = $0 }
                ))
            }

            Section("Auto-Save") {
                Toggle("Automatically save screenshots", isOn: Binding(
                    get: { preferences.autoSaveEnabled },
                    set: { preferences.autoSaveEnabled = $0 }
                ))

                HStack {
                    Text("Save to:")
                    Text(preferences.saveLocation.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose...") {
                        chooseFolder()
                    }
                }
            }

            Section("Image Format") {
                Picker("Format:", selection: Binding(
                    get: { preferences.imageFormat },
                    set: { preferences.imageFormat = $0 }
                )) {
                    ForEach(ImageFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                if preferences.imageFormat == .jpeg {
                    HStack {
                        Text("Quality:")
                        Slider(value: Binding(
                            get: { preferences.jpegQuality },
                            set: { preferences.jpegQuality = $0 }
                        ), in: 0.1...1.0, step: 0.05)
                        Text("\(Int(preferences.jpegQuality * 100))%")
                            .frame(width: 40)
                    }
                }
            }

            Section("Onboarding") {
                Button("Show Onboarding Again") {
                    onShowOnboarding()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 350)
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
