import SwiftUI

struct AppGridView: View {

    let apps: [AppItem]
    let columns: [GridItem]
    let onLaunch: (AppItem) -> Void
    let onUninstall: (AppItem) -> Void
    let onRevealInFinder: (AppItem) -> Void

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(apps) { app in
                AppIconCardView(
                    app: app,
                    onOpen: { onLaunch(app) },
                    onUninstall: { onUninstall(app) },
                    onRevealInFinder: { onRevealInFinder(app) }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
