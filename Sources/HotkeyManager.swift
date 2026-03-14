import Carbon
import AppKit

@MainActor
final class HotkeyManager {
    nonisolated(unsafe) private var hotKeyRefs: [EventHotKeyRef?] = []
    private var onFullScreen: @MainActor () -> Void
    private var onArea: @MainActor () -> Void
    private var onWindow: @MainActor () -> Void

    nonisolated(unsafe) private static var instance: HotkeyManager?

    init(onFullScreen: @escaping @MainActor () -> Void, onArea: @escaping @MainActor () -> Void, onWindow: @escaping @MainActor () -> Void) {
        self.onFullScreen = onFullScreen
        self.onArea = onArea
        self.onWindow = onWindow

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
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey | controlKey)

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
                default:
                    break
                }
            }

            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)

        let hotkeys: [(id: UInt32, keyCode: UInt32)] = [
            (1, 0x14),  // kVK_ANSI_3 -> Full Screen
            (2, 0x15),  // kVK_ANSI_4 -> Area
            (3, 0x17),  // kVK_ANSI_5 -> Window
        ]

        for hotkey in hotkeys {
            var ref: EventHotKeyRef?
            let hotkeyID = EventHotKeyID(signature: OSType(0x4D534E53), id: hotkey.id)
            let status = RegisterEventHotKey(hotkey.keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &ref)

            if status == noErr {
                hotKeyRefs.append(ref)
            } else {
                print("Failed to register hotkey \(hotkey.id): \(status)")
            }
        }
    }
}
