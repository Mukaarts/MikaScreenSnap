import Carbon
import AppKit

@MainActor
final class HotkeyManager {
    nonisolated(unsafe) private var hotKeyRefs: [EventHotKeyRef?] = []
    private var onFullScreen: @MainActor () -> Void
    private var onArea: @MainActor () -> Void
    private var onWindow: @MainActor () -> Void
    private var onCaptureText: @MainActor () -> Void
    private var onColorPicker: @MainActor () -> Void
    private var onMeasure: @MainActor () -> Void
    private var onHistory: @MainActor () -> Void

    nonisolated(unsafe) private static var instance: HotkeyManager?

    init(
        onFullScreen: @escaping @MainActor () -> Void,
        onArea: @escaping @MainActor () -> Void,
        onWindow: @escaping @MainActor () -> Void,
        onCaptureText: @escaping @MainActor () -> Void,
        onColorPicker: @escaping @MainActor () -> Void,
        onMeasure: @escaping @MainActor () -> Void,
        onHistory: @escaping @MainActor () -> Void
    ) {
        self.onFullScreen = onFullScreen
        self.onArea = onArea
        self.onWindow = onWindow
        self.onCaptureText = onCaptureText
        self.onColorPicker = onColorPicker
        self.onMeasure = onMeasure
        self.onHistory = onHistory

        HotkeyManager.instance = self
        registerHotkeys()
    }

    deinit {
        let refs = hotKeyRefs
        for ref in refs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
    }

    private func registerHotkeys() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            DispatchQueue.main.async { @MainActor in
                guard let manager = HotkeyManager.instance else { return }

                switch hotKeyID.id {
                case 1:
                    manager.onFullScreen()
                case 2:
                    manager.onArea()
                case 3:
                    manager.onWindow()
                case 4:
                    manager.onCaptureText()
                case 5:
                    manager.onColorPicker()
                case 6:
                    manager.onMeasure()
                case 7:
                    manager.onHistory()
                default:
                    break
                }
            }

            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)

        let ctrlCmdShift: UInt32 = UInt32(cmdKey | shiftKey | controlKey)
        let cmdShift: UInt32 = UInt32(cmdKey | shiftKey)

        let hotkeys: [(id: UInt32, keyCode: UInt32, modifiers: UInt32)] = [
            (1, 0x14, ctrlCmdShift),  // kVK_ANSI_3 -> Full Screen (⌃⇧⌘3)
            (2, 0x15, ctrlCmdShift),  // kVK_ANSI_4 -> Area (⌃⇧⌘4)
            (3, 0x17, ctrlCmdShift),  // kVK_ANSI_5 -> Window (⌃⇧⌘5)
            (4, 0x16, cmdShift),      // kVK_ANSI_6 -> Capture Text (⇧⌘6)
            (5, 0x1A, cmdShift),      // kVK_ANSI_7 -> Color Picker (⇧⌘7)
            (6, 0x1C, cmdShift),      // kVK_ANSI_8 -> Measure (⇧⌘8)
            (7, 0x04, cmdShift),      // kVK_ANSI_H -> History (⇧⌘H)
        ]

        for hotkey in hotkeys {
            var ref: EventHotKeyRef?
            let hotkeyID = EventHotKeyID(signature: OSType(0x4D534E53), id: hotkey.id)
            let status = RegisterEventHotKey(hotkey.keyCode, hotkey.modifiers, hotkeyID, GetApplicationEventTarget(), 0, &ref)

            if status == noErr {
                hotKeyRefs.append(ref)
            } else {
                print("Failed to register hotkey \(hotkey.id): \(status)")
            }
        }
    }
}
