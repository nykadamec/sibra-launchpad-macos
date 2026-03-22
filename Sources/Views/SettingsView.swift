import SwiftUI
import AppKit

struct SettingsView: View {

    @Bindable var store: UserDataStore
    @Environment(\.dismiss) private var dismiss
    let onReload: () -> Void

    @State private var selectedTab = 0
    @Namespace private var tabAnimation

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
            HStack(spacing: 4) {
                TabButton(title: "General", icon: "gearshape", isSelected: selectedTab == 0, namespace: tabAnimation) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
                TabButton(title: "Hotkeys", icon: "keyboard", isSelected: selectedTab == 1, namespace: tabAnimation) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
                TabButton(title: "About", icon: "info.circle", isSelected: selectedTab == 2, namespace: tabAnimation) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            }
            .padding(4)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.05))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

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
            .scrollIndicators(.hidden)
        }
        .frame(width: 400, height: 440)
        .background {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var generalTab: some View {
        settingsSection("Display") {
            SettingsRow(title: "Window Size", icon: "arrow.up.left.and.arrow.down.right", iconColor: .indigo) {
                Picker("", selection: Binding(
                    get: { store.settings.windowSize },
                    set: {
                        store.settings.windowSize = $0
                        store.save()
                        NotificationCenter.default.post(name: NSNotification.Name("SibraWindowSizeChanged"), object: nil)
                    }
                )) {
                    Text("Small").tag(UserDataStore.Settings.WindowSize.small)
                    Text("Normal").tag(UserDataStore.Settings.WindowSize.normal)
                    Text("Big").tag(UserDataStore.Settings.WindowSize.big)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            Divider().padding(.leading, 52)
            SettingsRow(title: "Icon Scale", icon: "square.grid.2x2.fill", iconColor: .blue) {
                Picker("", selection: Binding(
                    get: { store.settings.iconScale },
                    set: {
                        store.settings.iconScale = $0
                        store.save()
                        onReload()
                    }
                )) {
                    Text("Small").tag(UserDataStore.Settings.IconScale.small)
                    Text("Normal").tag(UserDataStore.Settings.IconScale.normal)
                    Text("Big").tag(UserDataStore.Settings.IconScale.big)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            Divider().padding(.leading, 52)
            SettingsRow(title: "Enable Categories", icon: "folder.fill", iconColor: .blue) {
                Toggle("", isOn: $store.settings.categoriesEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            Divider().padding(.leading, 52)
            SettingsRow(title: "Show System Apps", icon: "gearshape.fill", iconColor: .gray) {
                Toggle("", isOn: Binding(
                    get: { store.settings.showSystemApps },
                    set: {
                        store.settings.showSystemApps = $0
                        store.save()
                        onReload()
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }
            Divider().padding(.leading, 52)
            SettingsRow(title: "Launch Animation", icon: "sparkles", iconColor: .purple) {
                Toggle("", isOn: $store.settings.launchAnimation)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            Divider().padding(.leading, 52)
            SettingsRow(title: "One Click Start", icon: "cursorarrow.click.2", iconColor: .green) {
                Toggle("", isOn: Binding(
                    get: { store.settings.oneClickStart },
                    set: {
                        store.settings.oneClickStart = $0
                        store.save()
                        onReload()
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }
            Divider().padding(.leading, 52)
            SettingsRow(title: "Window Opacity", icon: "macwindow", iconColor: .teal) {
                HStack {
                    Slider(value: Binding(
                        get: { store.settings.windowOpacity },
                        set: {
                            store.settings.windowOpacity = $0
                            store.save()
                        }
                    ), in: 0.2...1.0)
                    .frame(width: 100)
                    
                    OpacityEditorView(opacity: $store.settings.windowOpacity) {
                        store.save()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var hotkeysTab: some View {
        settingsSection("Global Hotkey") {
            SettingsRow(
                title: "Toggle Sibra",
                subtitle: "Click the button and press a new key combination",
                icon: "keyboard.fill",
                iconColor: .gray
            ) {
                HotkeyDisplayButton(hotkey: store.settings.globalHotkey) { newHotkey in
                    store.settings.globalHotkey = newHotkey
                    store.save()
                }
            }
        }

        settingsSection("Per-App Hotkeys") {
            SettingsRow(
                title: "Enable Per-App Hotkeys",
                subtitle: "Right-click any app → Set Hotkey to assign a personal shortcut",
                icon: "command.square.fill",
                iconColor: .orange
            ) {
                Toggle("", isOn: $store.settings.hotkeysEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
    }

    @ViewBuilder
    private var aboutTab: some View {
        settingsSection("Sibra") {
            SettingsRow(title: "Version", icon: "info.circle.fill", iconColor: .blue) {
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")
                    .foregroundStyle(.secondary)
            }
            Divider().padding(.leading, 52)
            SettingsRow(title: "Log Path", subtitle: Log.logPath, icon: "doc.text.fill", iconColor: .gray) {
                EmptyView()
            }
        }

        settingsSection("Data") {
            SettingsRow(title: "Storage Path", subtitle: "~/Library/Application Support/Sibra/", icon: "externaldrive.fill", iconColor: .blue) {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.04))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
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
        }
        .onChange(of: isRecording) { _, newVal in
            if newVal {
                startMonitoring()
            } else {
                stopMonitoring()
                if !hotkeyText.isEmpty {
                    onChange(hotkeyText)
                    NotificationCenter.default.post(name: .globalHotkeyDidChange, object: nil)
                }
            }
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        stopMonitoring()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let chars = event.charactersIgnoringModifiers ?? ""
            var parts: [String] = []
            let mods = event.modifierFlags
            if mods.contains(.control) { parts.append("⌃") }
            if mods.contains(.option) { parts.append("⌥") }
            if mods.contains(.shift) { parts.append("⇧") }
            if mods.contains(.command) { parts.append("⌘") }
            
            var key = chars.uppercased()
            let keyCode = event.keyCode
            if keyCode == 49 { key = "Space" }
            else if keyCode == 36 { key = "Return" }
            else if keyCode == 53 { key = "Esc" }
            else if keyCode == 51 { key = "Backspace" }
            else if keyCode == 48 { key = "Tab" }
            
            if !key.isEmpty && !parts.isEmpty {
                hotkeyText = parts.joined() + key
                DispatchQueue.main.async {
                    isRecording = false
                }
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
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
#if os(macOS)
                        .fill(Color(nsColor: .windowBackgroundColor))
#else
                        .fill(Color(UIColor.systemBackground))
#endif
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .matchedGeometryEffect(id: "TabBackground", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = .blue
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.1))
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct OpacityEditorView: View {
    @Binding var opacity: Double
    var onSave: () -> Void
    
    @State private var isEditing = false
    @State private var textValue = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Group {
            if isEditing {
                TextField("", text: $textValue)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    .frame(width: 35)
                    .onSubmit {
                        commitChange()
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commitChange() }
                    }
                    .onAppear {
                        isFocused = true
                    }
            } else {
                Text("\(Int(opacity * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 35, alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        textValue = "\(Int(opacity * 100))"
                        isEditing = true
                    }
            }
        }
    }
    
    private func commitChange() {
        if let val = Double(textValue) {
            let clamped = min(max(val, 20.0), 100.0)
            opacity = clamped / 100.0
            onSave()
        }
        isEditing = false
    }
}
