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
    var selectedCategory: UserData.Category?
    var showSettings = false
    var isDraggingApp: AppItem?

    var filteredApps: [AppItem] {
        var apps = allApps

        // Filter by category
        if let cat = selectedCategory {
            apps = apps.filter { cat.appPaths.contains($0.bundleURL.path) }
        }

        // Filter by search
        if !searchText.isEmpty {
            apps = apps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var favouriteApps: [AppItem] {
        let userData = UserDataService.shared.data
        return userData.favourites.compactMap { path in
            allApps.first { $0.bundleURL.path == path }
        }
    }

    var categories: [UserData.Category] {
        UserDataService.shared.data.categories
    }

    var settings: UserData.Settings {
        UserDataService.shared.data.settings
    }

    private let scanner = AppScannerService()
    private nonisolated(unsafe) let launcher = AppLauncherService()
    private nonisolated(unsafe) let uninstaller = AppUninstallerService()

    // MARK: - Actions

    func loadApps() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let apps = try await scanner.scanApplications()
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
        UserDataService.shared.toggleFavourite(app)
    }

    func isFavourite(_ app: AppItem) -> Bool {
        UserDataService.shared.isFavourite(app)
    }

    func addToCategory(_ app: AppItem, category: UserData.Category) {
        UserDataService.shared.addApp(app, to: category)
    }

    func removeFromCategory(_ app: AppItem, category: UserData.Category) {
        UserDataService.shared.removeApp(app, from: category)
    }

    func category(for app: AppItem) -> UserData.Category? {
        UserDataService.shared.category(for: app)
    }

    func hotkey(for app: AppItem) -> String? {
        UserDataService.shared.hotkey(for: app)
    }

    func setHotkey(_ hotkey: String?, for app: AppItem) {
        UserDataService.shared.setHotkey(hotkey, for: app)
    }
}
