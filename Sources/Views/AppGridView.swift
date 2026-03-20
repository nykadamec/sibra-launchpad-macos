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

    private let columns = Array(repeating: GridItem(.fixed(88), spacing: 16), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(apps) { app in
                AppIconCardView(
                    app: app,
                    onLaunch: { onLaunch(app) },
                    onUninstall: { onUninstall(app) },
                    onRevealInFinder: { onRevealInFinder(app) },
                    onToggleFavourite: { onToggleFavourite(app) },
                    isFavourite: categories.isEmpty ? false : categories.flatMap { $0.appPaths }.contains(app.bundleURL.path),
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
