import AppKit
import SwiftUI

@MainActor
final class WindowManager {

    private(set) var mainWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var isSheetOpen = false
    private var statusItem: NSStatusItem?
    private var hotkeyManager: HotkeyManager?

    // MARK: - Entry

    func launch() {
        setupMainMenu()
        if UserDataStore.shared.settings.hasCompletedOnboarding {
            showMain()
        } else {
            showOnboarding()
        }
        setupMenuBar()
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Main Window

    func showMain() {
        let contentView = ContentView()
        mainWindow = createMainWindow(contentView: contentView)

        setupHotkey()
        setupWindowObservers()
        setupSettingsObserver()

        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createMainWindow(contentView: ContentView) -> NSWindow {
        let windowSize = UserDataStore.shared.settings.windowSize.size
        let opacity = UserDataStore.shared.settings.windowOpacity

        let window = SibraWindow(
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
        window.alphaValue = CGFloat(opacity)

        window.contentView = NSHostingView(rootView: contentView)

        centerWindow(window)
        window.minSize = windowSize
        window.maxSize = windowSize

        return window
    }

    private func setupSettingsObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SibraSettingsDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let opacity = notification.userInfo?["windowOpacity"] as? Double
            Task { @MainActor in
                if let opacity = opacity {
                    self?.setOpacity(opacity)
                }
            }
        }
    }

    private func setupWindowObservers() {
        guard let window = mainWindow else { return }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isSheetOpen else { return }
                self.mainWindow?.orderOut(nil)
            }
        }

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

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SibraWindowSizeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recenter()
            }
        }
    }

    // MARK: - Onboarding Window

    func showOnboarding() {
        let rootView = OnboardingContentView(onComplete: { [weak self] in
            self?.onOnboardingComplete()
        })

        let containerView = OnboardingWindowContentView(rootView: rootView)
        let hostingView = NoFirstResponderHostingView(rootView: containerView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 16
        hostingView.layer?.masksToBounds = true

        let win = SibraWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 440),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.hasShadow = true
        win.acceptsMouseMovedEvents = false
        win.isMovable = false
        win.isMovableByWindowBackground = false
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.contentView = hostingView

        centerWindow(win)
        win.makeKeyAndOrderFront(nil)

        onboardingWindow = win
        NSApp.activate(ignoringOtherApps: true)
    }

    private func onOnboardingComplete() {
        UserDataStore.shared.settings.hasCompletedOnboarding = true
        UserDataStore.shared.save()

        onboardingWindow?.orderOut(nil)
        onboardingWindow = nil

        showMain()
    }

    // MARK: - Window Controls

    func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideMainWindow() {
        mainWindow?.orderOut(nil)
    }

    func toggleMainWindow() {
        guard let window = mainWindow else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func recenter() {
        guard let window = mainWindow else { return }
        let newSize = UserDataStore.shared.settings.windowSize.size
        window.minSize = newSize
        window.maxSize = newSize

        let screen = NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        let frame = calculateCenteredFrame(size: newSize, in: visibleFrame)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame, display: true)
        }
    }

    func setOpacity(_ opacity: Double) {
        mainWindow?.alphaValue = CGFloat(opacity)
    }

    // MARK: - Helpers

    private func centerWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = calculateCenteredFrame(size: window.frame.size, in: screen.visibleFrame)
        window.setFrame(frame, display: true)
    }

    private func calculateCenteredFrame(size: NSSize, in visibleFrame: NSRect) -> NSRect {
        let x = visibleFrame.origin.x + (visibleFrame.width - size.width) / 2
        let y = visibleFrame.origin.y + (visibleFrame.height - size.height) / 2
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let bundleURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
               let appIcon = NSImage(contentsOf: bundleURL) {
                appIcon.size = NSSize(width: 18, height: 18)
                button.image = appIcon
            } else {
                button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "Sibra")
                button.image?.isTemplate = true
            }
        }

        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show Sibra", action: #selector(showMainWindowAction), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = NSMenu()
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc private func showMainWindowAction() {
        showMainWindow()
    }

    @objc private func showSettingsAction() {
        NotificationCenter.default.post(name: Notification.Name("SibraShowSettings"), object: nil)
        showMainWindow()
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyManager = HotkeyManager { [weak self] in
            self?.toggleMainWindow()
        }
        hotkeyManager?.register()

        NotificationCenter.default.addObserver(
            forName: .globalHotkeyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reregisterHotkey()
            }
        }
    }

    private func reregisterHotkey() {
        hotkeyManager?.unregister()
        hotkeyManager?.register()
    }

    // MARK: - Reopen

    func handleReopen() {
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - No-First-Responder Hosting View

class NoFirstResponderHostingView<Content: View>: NSHostingView<Content> {
    override var acceptsFirstResponder: Bool { false }
}



// MARK: - Onboarding Window Content Wrapper

struct OnboardingWindowContentView: View {
    let rootView: OnboardingContentView

    var body: some View {
        ZStack {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                forcedColorScheme: nil
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            rootView
        }
        .frame(width: 440, height: 440)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
