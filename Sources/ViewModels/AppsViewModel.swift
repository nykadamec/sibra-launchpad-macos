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

    var filteredApps: [AppItem] {
        if searchText.isEmpty {
            return allApps
        }
        return allApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Stateless services — safe to share across actors
    private nonisolated(unsafe) let scanner = AppScannerService()
    private nonisolated(unsafe) let launcher = AppLauncherService()
    private nonisolated(unsafe) let uninstaller = AppUninstallerService()

    // MARK: - Actions

    func loadApps() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let apps = try await scanner.scanApplications()
                self.allApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
}
