import SwiftUI
import AppKit

struct AppIconCardView: View {

    let app: AppItem
    let onOpen: () -> Void
    let onUninstall: () -> Void
    let onRevealInFinder: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .scaleEffect(isHovered ? 1.12 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)

            Text(app.name)
                .font(.system(size: 11, weight: .medium, design: .default))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 28)
                .foregroundStyle(.primary)
        }
        .frame(width: 88, height: 100)
        .contentShape(Rectangle())
        .opacity(isHovered ? 1.0 : 0.85)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            onOpen()
        }
        .contextMenu {
            Button("Open") {
                onOpen()
            }
            Button("Reveal in Finder") {
                onRevealInFinder()
            }
            Divider()
            Button("Uninstall", role: .destructive) {
                onUninstall()
            }
        }
        .help(app.name)
    }
}
