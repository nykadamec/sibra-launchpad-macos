import AppKit
import SwiftUI

extension Notification.Name {
    static let globalHotkeyDidChange = Notification.Name("GlobalHotkeyDidChange")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowManager: WindowManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowManager = WindowManager()
        windowManager.launch()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowManager.handleReopen()
        return true
    }
}

class SibraWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
