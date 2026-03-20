import Foundation
import AppKit

final class AppUninstallerService {

    enum UninstallError: Error, LocalizedError {
        case fileOperationFailed(String)

        var errorDescription: String? {
            switch self {
            case .fileOperationFailed(let message):
                return "Uninstall failed: \(message)"
            }
        }
    }

    func moveToTrash(_ app: AppItem) async throws {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: app.bundleURL.path) else {
            throw UninstallError.fileOperationFailed("Application not found at path.")
        }

        do {
            try fileManager.trashItem(at: app.bundleURL, resultingItemURL: nil)
        } catch {
            throw UninstallError.fileOperationFailed(error.localizedDescription)
        }
    }

    @MainActor
    func confirmUninstall(_ app: AppItem) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Uninstall \(app.name)?"
        alert.informativeText = "This will move \(app.name) to Trash. You can restore it from Trash later."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")

        return alert.runModal() == .alertFirstButtonReturn
    }
}
