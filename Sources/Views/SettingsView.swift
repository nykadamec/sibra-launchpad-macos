import SwiftUI

struct SettingsView: View {

    @Bindable var store: UserDataStore
    @Environment(\.dismiss) private var dismiss

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
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // General
                    settingsSection("General") {
                        Toggle("Enable Categories", isOn: $store.settings.categoriesEnabled)
                        Toggle("Launch Animation", isOn: $store.settings.launchAnimation)
                        Toggle("Custom Hotkeys", isOn: $store.settings.hotkeysEnabled)
                    }

                    // Startup
                    settingsSection("Startup") {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("Sibra toggles with ⌃Space. No login items needed.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // About
                    settingsSection("About") {
                        HStack {
                            Text("Sibra")
                                .font(.headline)
                            Spacer()
                            Text("v1.0")
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
                }
                .padding(24)
            }
        }
        .frame(width: 400, height: 420)
        .onChange(of: store.settings) { _, _ in
            store.save()
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
