import AppKit
import SwiftUI

extension Notification.Name {
    static let globalHotkeyDidChange = Notification.Name("GlobalHotkeyDidChange")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!
    private var hotkeyManager: HotkeyManager!
    private var statusItem: NSStatusItem?
    private var isSheetOpen = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setup()
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
            Task { @MainActor in
                guard let self = self, !self.isSheetOpen else { return }
                self.window.orderOut(nil)
            }
        }

        // Sheet tracking
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SibraSheetOpened"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isSheetOpen = true
            }
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SibraSheetClosed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isSheetOpen = false
            }
        }

        // Window hidden on launch — shown only via hotkey or menu bar
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

        let windowSize = UserDataStore.shared.settings.windowSize.size
        
        window = SibraWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
            styleMask: [.closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.isMovableByWindowBackground = false
        window.level = .floating
        window.acceptsMouseMovedEvents = true
        window.isMovable = false

        window.contentView = NSHostingView(rootView: contentView)

        // Center on the main screen using visibleFrame (respects menu bar & Dock)
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
            let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
            window.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
        } else {
            window.center()
        }

        window.minSize = windowSize
        window.maxSize = windowSize
        
        // Listen for size changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SibraWindowSizeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateWindowSize()
        }
    }

    @MainActor
    private func updateWindowSize() {
        guard let window = window else { return }
        let newSize = UserDataStore.shared.settings.windowSize.size
        
        // Calculate new frame keeping the center position
        var frame = window.frame
        let widthDiff = newSize.width - frame.width
        let heightDiff = newSize.height - frame.height
        
        frame.origin.x -= widthDiff / 2
        frame.origin.y -= heightDiff / 2
        frame.size = newSize
        
        // Update constraints first
        window.minSize = newSize
        window.maxSize = newSize
        
        // Animate frame change
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame, display: true)
        }
    }

    // MARK: - Menu Bar

    @MainActor
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                appIcon.size = NSSize(width: 18, height: 18)
                button.image = appIcon
            } else {
                button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "Sibra")
                button.image?.isTemplate = true
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Sibra", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc @MainActor
    private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc @MainActor
    private func showSettings() {
        NotificationCenter.default.post(name: Notification.Name("SibraShowSettings"), object: nil)
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

        // Re-register global hotkey when it changes
        NotificationCenter.default.addObserver(
            forName: .globalHotkeyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reregisterGlobalHotkey()
            }
        }
    }

    @MainActor
    func reregisterGlobalHotkey() {
        hotkeyManager.unregister()
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

class SibraWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
