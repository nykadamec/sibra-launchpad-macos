import SwiftUI
import AppKit

struct FullscreenContentView: View {

    @Bindable var store: UserDataStore
    @State private var viewModel = AppsViewModel()

    var body: some View {
        HStack(spacing: 0) {
            // Categories sidebar (full height)
            if store.settings.categoriesEnabled {
                CategorySidebarView(
                    categories: viewModel.categories,
                    selectedCategory: $viewModel.selectedCategory,
                    appCount: viewModel.allApps.count,
                    onAppDropped: { app, cat in viewModel.addToCategory(app, category: cat) },
                    allApps: { viewModel.allApps },
                    onAddCategory: { viewModel.addCategory(name: $0) }
                )
                .frame(width: 200)
                Divider()
            }

            // Main content
            VStack(spacing: 0) {
                // Top bar
                HStack(spacing: 16) {
                    // Exit fullscreen button
                    Button {
                        store.settings.displayMode = .windowed
                        store.save()
                        NotificationCenter.default.post(name: NSNotification.Name("SibraExitFullscreen"), object: nil)
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Exit Fullscreen")

                    SearchBarView(searchText: $viewModel.searchText)
                        .frame(maxWidth: .infinity)

                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Favourites
                if !viewModel.favouriteApps.isEmpty {
                    FavouritesRowView(
                        apps: viewModel.favouriteApps,
                        largeIcons: true,
                        onLaunch: { viewModel.launchApp($0) },
                        onRemove: { viewModel.toggleFavourite($0) }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    Divider()
                        .padding(.horizontal, 24)
                }

                // Grid
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Scanning…")
                        .progressViewStyle(.circular)
                    Spacer()
                } else if viewModel.filteredApps.isEmpty {
                    Spacer()
                    Text("No apps found")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        FullscreenAppGridView(
                            apps: viewModel.filteredApps,
                            onLaunch: { viewModel.launchApp($0) },
                            onUninstall: { viewModel.uninstallApp($0) },
                            onRevealInFinder: { viewModel.revealInFinder($0) },
                            onToggleFavourite: { viewModel.toggleFavourite($0) },
                            onAddToCategory: { app, cat in viewModel.addToCategory(app, category: cat) },
                            categories: viewModel.categories,
                            currentCategory: { viewModel.category(for: $0) }
                        )
                    }
                    .scrollIndicators(.hidden)
                }

                // Bottom bar
                HStack {
                    Text("\(viewModel.filteredApps.count) apps")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
        .onAppear {
            viewModel.loadApps()
            NSApp.activate(ignoringOtherApps: true)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(store: UserDataStore.shared, onReload: {
                viewModel.loadApps()
            })
            .onAppear {
                NotificationCenter.default.post(name: NSNotification.Name("SibraSheetOpened"), object: nil)
            }
            .onDisappear {
                NotificationCenter.default.post(name: NSNotification.Name("SibraSheetClosed"), object: nil)
            }
        }
        .onKeyPress(.escape) {
            store.settings.displayMode = .windowed
            store.save()
            NotificationCenter.default.post(name: NSNotification.Name("SibraExitFullscreen"), object: nil)
            return .handled
        }
    }
}

struct FullscreenAppGridView: View {

    let apps: [AppItem]
    let onLaunch: (AppItem) -> Void
    let onUninstall: (AppItem) -> Void
    let onRevealInFinder: (AppItem) -> Void
    let onToggleFavourite: (AppItem) -> Void
    let onAddToCategory: (AppItem, UserDataStore.Category) -> Void
    let categories: [UserDataStore.Category]
    let currentCategory: (AppItem) -> UserDataStore.Category?

    private let columns = Array(repeating: GridItem(.fixed(100), spacing: 20), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach(apps) { app in
                FullscreenAppCardView(
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
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

struct FullscreenAppCardView: View {

    let app: AppItem
    let onLaunch: () -> Void
    let onUninstall: () -> Void
    let onRevealInFinder: () -> Void
    let onToggleFavourite: () -> Void
    let isFavourite: Bool
    let onAddToCategory: (UserDataStore.Category) -> Void
    let categories: [UserDataStore.Category]
    let currentCategory: UserDataStore.Category?

    @State private var isHovered = false
    @State private var isLaunching = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .scaleEffect(isLaunching ? 0.82 : (isHovered ? 1.1 : 1.0))
                    .opacity(isLaunching ? 0.0 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: isLaunching)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)

                if isLaunching {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
            }

            Text(app.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32)
                .foregroundStyle(.white)
        }
        .frame(width: 100, height: 115)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            launchWithAnimation()
        }
        .contextMenu {
            Button("Open") { launchWithAnimation() }
            Button("Reveal in Finder") { onRevealInFinder() }
            Divider()
            Button {
                onToggleFavourite()
            } label: {
                Label(isFavourite ? "Remove from Favourites" : "Add to Favourites",
                      systemImage: isFavourite ? "star.fill" : "star")
            }
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
            Button("Uninstall", role: .destructive) { onUninstall() }
        }
    }

    private func launchWithAnimation() {
        withAnimation(.easeOut(duration: 0.15)) { isLaunching = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onLaunch()
            withAnimation(.easeIn(duration: 0.1)) { isLaunching = false }
        }
    }
}
