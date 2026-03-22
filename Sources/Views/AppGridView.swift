import SwiftUI

struct AppGridView: View {

    let apps: [AppItem]
    let onLaunch: (AppItem) -> Void
    let onUninstall: (AppItem) -> Void
    let onRevealInFinder: (AppItem) -> Void
    let onToggleFavourite: (AppItem) -> Void
    let onAddToCategory: (AppItem, UserDataStore.Category) -> Void
    let categories: [UserDataStore.Category]
    let currentCategory: (AppItem) -> UserDataStore.Category?

    private var columns: [GridItem] {
        let cardWidth = UserDataStore.shared.settings.iconScale.cardWidth
        return [GridItem(.adaptive(minimum: cardWidth, maximum: cardWidth + 12), spacing: 16)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(apps) { app in
                AppIconCardView(
                    app: app,
                    onLaunch: { onLaunch(app) },
                    onUninstall: { onUninstall(app) },
                    onRevealInFinder: { onRevealInFinder(app) },
                    onToggleFavourite: { onToggleFavourite(app) },
                    isFavourite: UserDataStore.shared.isFavourite(app),
                    onAddToCategory: { cat in onAddToCategory(app, cat) },
                    categories: categories,
                    currentCategory: currentCategory(app)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}
