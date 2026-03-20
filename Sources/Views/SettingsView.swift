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
        }

        settingsSection("Appearance") {
            Toggle("Launch Animation", isOn: $store.settings.launchAnimation)
        }

        settingsSection("Hotkeys") {
            Toggle("Custom Hotkeys", isOn: $store.settings.hotkeysEnabled)
        }
    }

    @ViewBuilder
    private var hotkeysTab: some View {
        settingsSection("Global Hotkey") {
            HStack {
                Text("Toggle Sibra")
                Spacer()
                Text("⌃Space")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Press to show or hide Sibra window")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if store.settings.hotkeysEnabled {
            settingsSection("Per-App Hotkeys") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Right-click any app → Set Hotkey… to assign a personal shortcut")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        .focusable(false)
    }
}
