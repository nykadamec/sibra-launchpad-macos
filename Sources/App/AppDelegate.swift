import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!
    private var hotkeyManager: HotkeyManager!
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await self.setup()
        }
    }

    @MainActor
    private func setup() {
        setupWindow()
        setupMenuBar()
        setupHotkey()
        NSApp.setActivationPolicy(.accessory)

        // Hide window when it loses focus (click outside)
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak window] _ in
            DispatchQueue.main.async {
                window?.orderOut(nil)
            }
        }

        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Task { @MainActor in
            window?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    // MARK: - Window

    @MainActor
    private func setupWindow() {
        let contentView = ContentView()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 560),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.toolbarStyle = .unified
        // Hide window control buttons (traffic lights)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.level = .floating
        window.acceptsMouseMovedEvents = true
        window.isMovable = false

        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        window.minSize = NSSize(width: 600, height: 400)
    }

    // MARK: - Menu Bar

    @MainActor
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "Sibra")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Sibra", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc @MainActor
    private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Global Hotkey ⌘Space

    @MainActor
    private func setupHotkey() {
        hotkeyManager = HotkeyManager { [weak self] in
            self?.toggleWindow()
        }
        hotkeyManager.register()
    }

    @MainActor
    func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    deinit {
        hotkeyManager.unregister()
    }
}
