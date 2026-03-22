import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!
    private var hotkeyManager: HotkeyManager!
    private var statusItem: NSStatusItem?
    private var isSheetOpen = false

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

        // Hide window when it loses focus (click outside) — but not if a sheet is open
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, !self.isSheetOpen else { return }
            DispatchQueue.main.async {
                self.window.orderOut(nil)
            }
        }

        // Sheet tracking
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SibraSheetOpened"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isSheetOpen = true
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SibraSheetClosed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isSheetOpen = false
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
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.toolbarStyle = .unified
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isOpaque = false
        window.hasShadow = false
        window.isMovableByWindowBackground = false
        window.level = .floating
        window.acceptsMouseMovedEvents = true
        window.isMovable = false

        window.contentView = NSHostingView(rootView: contentView)

        // Center on the main screen using visibleFrame (respects menu bar & Dock)
        let windowSize = NSSize(width: 800, height: 560)
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
            let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
            window.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
        } else {
            window.center()
        }

        window.minSize = NSSize(width: 800, height: 560)
        window.maxSize = NSSize(width: 800, height: 560)
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

    // MARK: - Global Hotkey

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
