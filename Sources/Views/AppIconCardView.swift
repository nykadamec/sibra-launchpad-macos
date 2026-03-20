import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AppIconCardView: View {

    let app: AppItem
    let onLaunch: () -> Void
    let onUninstall: () -> Void
    let onRevealInFinder: () -> Void
    let onToggleFavourite: () -> Void
    let isFavourite: Bool
    let onAddToCategory: (UserData.Category) -> Void
    let categories: [UserData.Category]
    let currentCategory: UserData.Category?

    @State private var isHovered = false
    @State private var isLaunching = false
    @State private var showHotkeySheet = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isLaunching ? 0.82 : (isHovered ? 1.12 : 1.0))
                    .opacity(isLaunching ? 0.0 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: isLaunching)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)

                if isLaunching {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }

            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 28)
                .foregroundStyle(.primary)
        }
        .frame(width: 88, height: 100)
        .contentShape(Rectangle())
        .opacity(isHovered ? 1.0 : 0.85)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            launchWithAnimation()
        }
        .contextMenu {
            Button("Open") {
                launchWithAnimation()
            }
            Button("Reveal in Finder") {
                onRevealInFinder()
            }
            Divider()

            // Favourite
            Button {
                onToggleFavourite()
            } label: {
                Label(
                    isFavourite ? "Remove from Favourites" : "Add to Favourites",
                    systemImage: isFavourite ? "star.fill" : "star"
                )
            }

            // Categories submenu
            if !categories.isEmpty {
                Menu("Add to Category") {
                    ForEach(categories) { cat in
                        Button {
                            onAddToCategory(cat)
                        } label: {
                            HStack {
                                Text(cat.name)
                                Spacer()
                                if currentCategory?.id == cat.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            Divider()
            Button {
                showHotkeySheet = true
            } label: {
                Label("Set Hotkey…", systemImage: "keyboard")
            }

            Divider()
            Button("Uninstall", role: .destructive) {
                onUninstall()
            }
        }
        .sheet(isPresented: $showHotkeySheet) {
            HotkeyRecorderSheet(app: app) { hotkey in
                UserDataService.shared.setHotkey(hotkey, for: app)
            }
        }
    }

    private func launchWithAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            isLaunching = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onLaunch()
            withAnimation(.easeIn(duration: 0.1)) {
                isLaunching = false
            }
        }
    }
}

// MARK: - Hotkey Recorder Sheet

struct HotkeyRecorderSheet: View {

    let app: AppItem
    let onSave: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hotkeyText = ""
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        VStack(spacing: 16) {
            Text("Set Hotkey for \(app.name)")
                .font(.headline)

            Text("Click record then press a key combination")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isRecording ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.06))

                RoundedRectangle(cornerRadius: 8)
                    .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)

                VStack(spacing: 4) {
                    Text(hotkeyText.isEmpty ? "—" : hotkeyText)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                    if isRecording {
                        Text("Recording…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 60)
            .onTapGesture {
                isRecording = true
            }

            HStack(spacing: 12) {
                Button("Clear") {
                    hotkeyText = ""
                    onSave(nil)
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button(isRecording ? "Click to stop" : "Record") {
                    isRecording.toggle()
                }
                .buttonStyle(.bordered)
                .disabled(!isRecording)

                Button("Save") {
                    onSave(hotkeyText.isEmpty ? nil : hotkeyText)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(hotkeyText.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .onAppear {
            if let existing = UserDataService.shared.hotkey(for: app) {
                hotkeyText = existing
            }
            startMonitoring()
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
            if !key.isEmpty && parts.count > 0 {
                hotkeyText = parts.joined() + key
                isRecording = false
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

