import Foundation

actor AppScannerService {

    enum ScanError: Error, LocalizedError {
        case applicationsDirectoryNotFound

        var errorDescription: String? {
            switch self {
            case .applicationsDirectoryNotFound:
                return "Could not locate /Applications directory."
            }
        }
    }

    func scanApplications() async throws -> [AppItem] {
        let fileManager = FileManager.default
        let applicationsURL = URL(fileURLWithPath: "/Applications")

        guard fileManager.fileExists(atPath: applicationsURL.path) else {
            throw ScanError.applicationsDirectoryNotFound
        }

        let contents = try fileManager.contentsOfDirectory(
            at: applicationsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        let showSystem = UserDataStore.shared.settings.showSystemApps

        let appBundles = contents.filter { url in
            guard url.pathExtension == "app" else { return false }
            if showSystem { return true }

            // Hide system apps
            let path = url.path
            let systemPaths = [
                "/System/",
                "/Library/Apple/System/",
                "/System/Applications",
                "/System/Applications/Utilities"
            ]
            let isSystem = systemPaths.contains { path.hasPrefix($0) }
            return !isSystem
        }

        return appBundles.map { AppItem(bundleURL: $0) }
    }
}
