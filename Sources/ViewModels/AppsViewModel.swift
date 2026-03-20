import Foundation
import AppKit

@Observable
@MainActor
final class AppsViewModel {

    // MARK: - Properties

    private(set) var allApps: [AppItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var searchText: String = ""
    var selectedCategory: UserDataStore.Category?
    var showSettings = false
    var isDraggingApp: AppItem?

    var filteredApps: [AppItem] {
        var apps = allApps

        if let cat = selectedCategory {
            apps = apps.filter { cat.appPaths.contains($0.bundleURL.path) }
        }

        if !searchText.isEmpty {
            apps = apps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var favouriteApps: [AppItem] {
        UserDataStore.shared.favourites.compactMap { path in
            allApps.first { $0.bundleURL.path == path }
        }
    }

    var categories: [UserDataStore.Category] {
        UserDataStore.shared.categories
    }

    var settings: UserDataStore.Settings {
        get { UserDataStore.shared.settings }
        set { UserDataStore.shared.settings = newValue; UserDataStore.shared.save() }
    }

    private let scanner = AppScannerService()
    private nonisolated(unsafe) let launcher = AppLauncherService()
    private nonisolated(unsafe) let uninstaller = AppUninstallerService()

    // MARK: - Actions

    func loadApps() {
        isLoading = true
        errorMessage = nil

        let showSystem = UserDataStore.shared.settings.showSystemApps

        Task {
            do {
                let apps = try await scanner.scanApplications(showSystemApps: showSystem)
                self.allApps = apps
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func launchApp(_ app: AppItem) {
        Task {
            do {
                try await launcher.launch(app)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func uninstallApp(_ app: AppItem) {
        guard uninstaller.confirmUninstall(app) else { return }

        Task {
            do {
                try await uninstaller.moveToTrash(app)
                self.allApps.removeAll { $0.id == app.id }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func revealInFinder(_ app: AppItem) {
        NSWorkspace.shared.selectFile(app.bundleURL.path, inFileViewerRootedAtPath: "")
    }

    func toggleFavourite(_ app: AppItem) {
        UserDataStore.shared.toggleFavourite(app)
    }

    func isFavourite(_ app: AppItem) -> Bool {
        UserDataStore.shared.isFavourite(app)
    }

    func addToCategory(_ app: AppItem, category: UserDataStore.Category) {
        UserDataStore.shared.addApp(app, to: category)
    }

    func addCategory(name: String) {
        UserDataStore.shared.addCategory(name: name)
    }

    func removeFromCategory(_ app: AppItem, category: UserDataStore.Category) {
        UserDataStore.shared.removeApp(app, from: category)
    }

    func category(for app: AppItem) -> UserDataStore.Category? {
        UserDataStore.shared.category(for: app)
    }

    func hotkey(for app: AppItem) -> String? {
        UserDataStore.shared.hotkey(for: app)
    }

    func setHotkey(_ hotkey: String?, for app: AppItem) {
        UserDataStore.shared.setHotkey(hotkey, for: app)
    }
}
