import SwiftUI
import AppKit

struct SearchBarView: View {

    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    @State private var textField = NSTextField()
    @State private var isSettingsHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13, weight: .medium))

            TextField("Search applications…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }

            Button {
                // TODO: Implement settings action
            } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(isSettingsHovered ? .primary : .secondary)
                    .font(.system(size: 14))
                    .rotationEffect(.degrees(isSettingsHovered ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isSettingsHovered)
            }
            .buttonStyle(.plain)
            .help("Nastavení")
            .onHover { hovering in
                isSettingsHovered = hovering
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 36)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
        }
        .onAppear {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                isFocused = true
            }
        }
    }
}
