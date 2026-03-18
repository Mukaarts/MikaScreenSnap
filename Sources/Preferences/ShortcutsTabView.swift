// ShortcutsTabView.swift
// MikaScreenSnap
//
// Shortcuts preferences: hotkey list with inline recorder.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI
import Carbon

struct ShortcutsTabView: View {
    let hotkeyManager: HotkeyManager

    @State private var bindings: [HotkeyAction: HotkeyBinding] = [:]
    @State private var recordingAction: HotkeyAction?
    @State private var conflictMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Shortcuts")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 0) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(Array(HotkeyAction.allCases.enumerated()), id: \.element) { index, action in
                            if index > 0 {
                                Divider()
                            }
                            HStack {
                                Label(action.label, systemImage: action.systemImage)
                                Spacer()
                                ShortcutRecorderView(
                                    binding: bindings[action] ?? action.defaultBinding,
                                    isRecording: recordingAction == action,
                                    onStartRecording: {
                                        recordingAction = action
                                        conflictMessage = nil
                                    },
                                    onRecord: { newBinding in
                                        recordBinding(newBinding, for: action)
                                    },
                                    onCancel: {
                                        recordingAction = nil
                                    }
                                )
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                    }
                }

                if let conflict = conflictMessage {
                    Label(conflict, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.top, 6)
                }
            }

            HStack {
                Spacer()
                Button {
                    restoreDefaults()
                } label: {
                    Label("Restore Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .onAppear {
            bindings = hotkeyManager.currentBindings
        }
    }

    private func recordBinding(_ binding: HotkeyBinding, for action: HotkeyAction) {
        for (otherAction, otherBinding) in bindings where otherAction != action {
            if otherBinding == binding {
                conflictMessage = "Conflict with \"\(otherAction.label)\""
                recordingAction = nil
                return
            }
        }

        bindings[action] = binding
        recordingAction = nil
        conflictMessage = nil
        hotkeyManager.reRegisterAll(bindings: bindings)
    }

    private func restoreDefaults() {
        var defaults: [HotkeyAction: HotkeyBinding] = [:]
        for action in HotkeyAction.allCases {
            defaults[action] = action.defaultBinding
        }
        bindings = defaults
        conflictMessage = nil
        hotkeyManager.reRegisterAll(bindings: defaults)
    }
}

// MARK: - HotkeyAction Icons

extension HotkeyAction {
    var systemImage: String {
        switch self {
        case .fullScreen:  return "rectangle.dashed.and.arrow.up.forward"
        case .area:        return "rectangle.dashed"
        case .window:      return "macwindow"
        case .captureText: return "text.viewfinder"
        case .colorPicker: return "eyedropper"
        case .measure:     return "ruler"
        case .history:     return "clock.arrow.circlepath"
        }
    }
}

// MARK: - ShortcutRecorderView

struct ShortcutRecorderView: View {
    let binding: HotkeyBinding
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onRecord: (HotkeyBinding) -> Void
    let onCancel: () -> Void

    @State private var keyMonitor: Any?

    var body: some View {
        Button {
            if isRecording {
                onCancel()
            } else {
                onStartRecording()
            }
        } label: {
            Text(isRecording ? "Press shortcut..." : binding.displayString)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isRecording ? Color.accentColor : Color.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(minWidth: 100)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.quaternary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    isRecording ? Color.accentColor : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                )
        }
        .buttonStyle(.plain)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    private func startMonitoring() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == 53 {
                onCancel()
                return nil
            }

            let carbonModifiers = carbonModifiersFromNSEvent(event.modifierFlags)
            let hasCmdOrCtrl = event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control)
            guard hasCmdOrCtrl else { return nil }

            let newBinding = HotkeyBinding(
                keyCode: UInt32(event.keyCode),
                modifiers: carbonModifiers
            )
            onRecord(newBinding)
            return nil
        }
    }

    private func stopMonitoring() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func carbonModifiersFromNSEvent(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        return carbon
    }
}
