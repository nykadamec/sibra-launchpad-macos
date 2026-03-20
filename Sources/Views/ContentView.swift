import SwiftUI
import AppKit

struct ContentView: View {

    @State private var viewModel = AppsViewModel()

    var body: some View {
        HStack(spacing: 0) {
            // Categories sidebar
            if viewModel.settings.categoriesEnabled {
                CategorySidebarView(
                    categories: viewModel.categories,
                    selectedCategory: $viewModel.selectedCategory,
                    appCount: viewModel.allApps.count
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
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Favourites row
                if !viewModel.favouriteApps.isEmpty {
                    FavouritesRowView(
                        apps: viewModel.favouriteApps,
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
        .frame(minWidth: 640, minHeight: 420)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial.opacity(0.93))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(settings: Binding(
                get: { viewModel.settings },
                set: { new in
                    UserDataService.shared.updateSettings { $0 = new }
                }
            ))
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
        .onKeyPress(.escape) {
            NSApp.keyWindow?.orderOut(nil)
            return .handled
        }
    }
}
