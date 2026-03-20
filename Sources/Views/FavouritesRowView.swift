import SwiftUI

struct FavouritesRowView: View {

    let apps: [AppItem]
    let largeIcons: Bool
    let onLaunch: (AppItem) -> Void
    let onRemove: (AppItem) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Favourites")
                .font(.system(size: largeIcons ? 13 : 11, weight: .medium))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: largeIcons ? 8 : 4) {
                    ForEach(apps) { app in
                        FavouriteIconView(
                            app: app,
                            largeIcon: largeIcons,
                            onLaunch: { onLaunch(app) },
                            onRemove: { onRemove(app) }
                        )
                    }
                }
            }
        }
    }
}

struct FavouriteIconView: View {

    let app: AppItem
    let largeIcon: Bool
    let onLaunch: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    private var iconSize: CGFloat { largeIcon ? 56 : 40 }
    private var cardWidth: CGFloat { largeIcon ? 64 : 48 }

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: largeIcon ? 12 : 8))
                    .scaleEffect(isHovered ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
                    .onHover { isHovered = $0 }
                    .onTapGesture(count: 2) {
                        onLaunch()
                    }
                    .contextMenu {
                        Button("Launch") { onLaunch() }
                        Button("Remove from Favourites", role: .destructive) { onRemove() }
                    }

                if isHovered {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: largeIcon ? 12 : 10))
                        .foregroundStyle(.white, .red)
                        .offset(x: 4, y: -4)
                        .onTapGesture { onRemove() }
                }
            }
            Text(app.name)
                .font(.system(size: largeIcon ? 11 : 9))
                .lineLimit(1)
                .frame(width: cardWidth)
                .foregroundStyle(largeIcon ? .primary : .secondary)
        }
    }
}
