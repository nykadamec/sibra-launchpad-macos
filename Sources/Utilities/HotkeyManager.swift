import Carbon
import Foundation

final class HotkeyManager: @unchecked Sendable {

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let callback: @MainActor () -> Void

    private static let hotkeyID = EventHotKeyID(signature: OSType(0x53495241), id: 1) // "SIRA"

    init(callback: @escaping @MainActor () -> Void) {
        self.callback = callback
    }

    func register() {
        let hotkeyString = UserDataStore.shared.settings.globalHotkey
        let (keyCode, modifiers) = HotkeyManager.parse(hotkeyString)

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerCallback: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotkeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            if status == noErr && hotkeyID.id == HotkeyManager.hotkeyID.id {
                let cb = manager.callback
                Task { @MainActor in
                    cb()
                }
            }

            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerCallback,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        let hotkeyIDStruct = HotkeyManager.hotkeyID
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyIDStruct,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }

    // MARK: - Parsing

    private static let modifierMap: [String: UInt32] = [
        "⌃": UInt32(controlKey),
        "⌘": UInt32(cmdKey),
        "⇧": UInt32(shiftKey),
        "⌥": UInt32(optionKey),
    ]

    private static let keycodeMap: [String: UInt32] = [
        "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3, "G": 5,
        "H": 4, "I": 34, "J": 38, "K": 40, "L": 37, "M": 46, "N": 45,
        "O": 31, "P": 35, "Q": 12, "R": 15, "S": 1, "T": 17, "U": 32,
        "V": 9, "W": 13, "X": 7, "Y": 16, "Z": 6,
        "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
        "6": 22, "7": 26, "8": 28, "9": 25,
        "SPACE": 49, "←": 123, "→": 124, "↑": 126, "↓": 125,
        "RETURN": 36, "ENTER": 36, "TAB": 48, "ESCAPE": 53, "ESC": 53,
        "DELETE": 51, "BACKSPACE": 51,
    ]

    static func parse(_ hotkey: String) -> (keyCode: UInt32, modifiers: UInt32) {
        var modifiers: UInt32 = 0
        var keyPart = hotkey

        // Extract modifiers from the beginning of the string
        while let prefix = keyPart.prefix(1).description as String?,
              let mod = modifierMap[prefix] {
            modifiers |= mod
            keyPart = String(keyPart.dropFirst(prefix.count))
        }

        // Look up keycode (case-insensitive)
        let upper = keyPart.uppercased()
        let keyCode = keycodeMap[upper] ?? 49 // default to Space (49)

        return (keyCode, modifiers)
    }
}
