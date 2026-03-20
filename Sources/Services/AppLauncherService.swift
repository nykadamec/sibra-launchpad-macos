import Foundation
import AppKit

final class AppLauncherService {

    enum LaunchError: Error, LocalizedError {
        case failedToLaunch(String)

        var errorDescription: String? {
            switch self {
            case .failedToLaunch(let name):
                return "Failed to launch \(name). The application may be damaged or missing."
            }
        }
    }

    func launch(_ app: AppItem) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        do {
            try await NSWorkspace.shared.openApplication(
                at: app.bundleURL,
                configuration: configuration
            )
        } catch {
            throw LaunchError.failedToLaunch(app.name)
        }
    }
}
