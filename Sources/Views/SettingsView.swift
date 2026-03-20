import SwiftUI

struct SettingsView: View {

    @Bindable var store: UserDataStore
    @Environment(\.dismiss) private var dismiss
    let onReload: () -> Void

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Tab bar
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gearshape", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Hotkeys", icon: "keyboard", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "About", icon: "info.circle", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case 0:
                        generalTab
                    case 1:
                        hotkeysTab
                    case 2:
                        aboutTab
                    default:
                        EmptyView()
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 400, height: 440)
    }

    @ViewBuilder
    private var generalTab: some View {
        settingsSection("Display") {
            Toggle("Enable Categories", isOn: $store.settings.categoriesEnabled)
            Toggle("Show System Apps", isOn: Binding(
                get: { store.settings.showSystemApps },
                set: {
                    store.settings.showSystemApps = $0
                    store.save()
                    onReload()
                }
            ))
            Toggle("Launch Animation", isOn: $store.settings.launchAnimation)
        }

        settingsSection("Display Mode") {
            HStack(spacing: 8) {
                ModeButton(
                    title: "Windowed",
                    icon: "rectangle",
                    isSelected: store.settings.displayMode == .windowed
                ) {
                    store.settings.displayMode = .windowed
                    store.save()
                    NotificationCenter.default.post(name: NSNotification.Name("SibraExitFullscreen"), object: nil)
                }

                ModeButton(
                    title: "Fullscreen",
                    icon: "arrow.up.left.and.arrow.down.right",
                    isSelected: store.settings.displayMode == .fullscreen
                ) {
                    store.settings.displayMode = .fullscreen
                    store.save()
                    NotificationCenter.default.post(name: NSNotification.Name("SibraEnterFullscreen"), object: nil)
                }
            }
        }
    }

    @ViewBuilder
    private var hotkeysTab: some View {
        settingsSection("Global Hotkey") {
            HStack {
                Text("Toggle Sibra")
                Spacer()
                HotkeyDisplayButton(hotkey: store.settings.globalHotkey) { newHotkey in
                    store.settings.globalHotkey = newHotkey
                    store.save()
                }
            }
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Click the button and press a new key combination")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        settingsSection("Per-App Hotkeys") {
            Toggle("Enable Per-App Hotkeys", isOn: $store.settings.hotkeysEnabled)
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Right-click any app → Set Hotkey to assign a personal shortcut")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var aboutTab: some View {
        settingsSection("Sibra") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text("Log: /tmp/Sibra.log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        settingsSection("Data") {
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text("~/Library/Application Support/Sibra/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            }
        }
    }
}

struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.15))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HotkeyDisplayButton: View {
    let hotkey: String
    let onChange: (String) -> Void

    @State private var isRecording = false
    @State private var hotkeyText = ""
    @State private var monitor: Any?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.06))
            RoundedRectangle(cornerRadius: 6)
                .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1)

            VStack(spacing: 2) {
                Text(isRecording ? (hotkeyText.isEmpty ? "Recording..." : hotkeyText) : hotkey)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                if isRecording {
                    Text("press keys…")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 110, height: 44)
        .onTapGesture {
            isRecording = true
            hotkeyText = ""
            startMonitoring()
        }
        .onChange(of: isRecording) { _, newVal in
            if !newVal {
                stopMonitoring()
                if !hotkeyText.isEmpty {
                    onChange(hotkeyText)
                }
            }
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecording else { return event }
            let chars = event.charactersIgnoringModifiers ?? ""
            var parts: [String] = []
            let mods = event.modifierFlags
            if mods.contains(.control) { parts.append("⌃") }
            if mods.contains(.option) { parts.append("⌥") }
            if mods.contains(.shift) { parts.append("⇧") }
            if mods.contains(.command) { parts.append("⌘") }
            let key = chars.uppercased()
            if !key.isEmpty && !parts.isEmpty {
                hotkeyText = parts.joined() + key
                return nil
            }
            return nil
        }
    }

    private func stopMonitoring() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
