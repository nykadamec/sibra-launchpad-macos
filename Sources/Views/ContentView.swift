import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var forcedColorScheme: ColorScheme? = nil

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        applyAppearance(to: view, context: context)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        applyAppearance(to: nsView, context: context)
    }

    private func applyAppearance(to view: NSVisualEffectView, context: Context) {
        let scheme = forcedColorScheme ?? (context.environment.colorScheme == .dark ? .dark : .light)
        view.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
    }
}

struct ContentView: View {

    @State private var viewModel = AppsViewModel()
    @State private var isHoveringSettings = false

    private func colorScheme(for theme: UserDataStore.Settings.Theme) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Categories sidebar
            if viewModel.settings.categoriesEnabled {
                CategorySidebarView(
                    categories: viewModel.categories,
                    selectedCategory: $viewModel.selectedCategory,
                    appCount: viewModel.allApps.count,
                    onAppDropped: { app, cat in viewModel.addToCategory(app, category: cat) },
                    allApps: { viewModel.allApps },
                    onAddCategory: { viewModel.addCategory(name: $0) }
                )
                .frame(width: 160)
                Divider()
            }

            // Main content
            VStack(spacing: 0) {
                // Top bar
                HStack(spacing: 12) {
                    SearchBarView(searchText: $viewModel.searchText)
                        .frame(maxWidth: .infinity)

                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundStyle(isHoveringSettings ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    .scaleEffect(isHoveringSettings ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHoveringSettings)
                    .sibraCursor(.pointingHand)
                    .onHover { hovering in
                        isHoveringSettings = hovering
                    }

                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Favourites row
                if !viewModel.favouriteApps.isEmpty {
                    FavouritesRowView(
                        apps: viewModel.favouriteApps,
                        largeIcons: false,
                        onLaunch: { viewModel.launchApp($0) },
                        onRemove: { viewModel.toggleFavourite($0) }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    Divider()
                        .padding(.horizontal, 20)
                }

                // Grid
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Scanning applications…")
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
                        AppGridView(
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
            }
        }
        .frame(minWidth: viewModel.settings.windowSize.size.width, minHeight: viewModel.settings.windowSize.size.height)
        .preferredColorScheme(colorScheme(for: viewModel.settings.theme))
        .background {
            ZStack {
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    forcedColorScheme: colorScheme(for: viewModel.settings.theme)
                )
                    .ignoresSafeArea()
                
                Color(NSColor.windowBackgroundColor).opacity(0.5)
            }
            .opacity(viewModel.settings.windowOpacity)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .ignoresSafeArea(.all, edges: .top)
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
        .onAppear {
            viewModel.loadApps()
            NSApp.activate(ignoringOtherApps: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SibraShowSettings"))) { _ in
            viewModel.showSettings = true
        }
        .onKeyPress(.escape) {
            NSApp.keyWindow?.orderOut(nil)
            return .handled
        }
    }
}

extension View {
    func sibraCursor(_ cursor: NSCursor) -> some View {
        self.onContinuousHover { phase in
            switch phase {
            case .active:
                cursor.push()
            case .ended:
                NSCursor.pop()
            }
        }
    }
}
