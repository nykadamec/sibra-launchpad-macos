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

        let appBundles = contents.filter { url in
            url.pathExtension == "app"
        }

        return appBundles.map { AppItem(bundleURL: $0) }
    }
}
