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
                // Carbon hotkey events always fire on the main thread
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

        // Register ⌃Space — keycode 49 = Space, modifiers = control
        let modifiers: UInt32 = UInt32(controlKey)
        let keyCode: UInt32 = 49

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
}
