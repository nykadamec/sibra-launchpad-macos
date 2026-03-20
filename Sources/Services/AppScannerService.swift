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

    private let applicationDirs: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications")
    ]

    func scanApplications(showSystemApps: Bool) async throws -> [AppItem] {
        let fileManager = FileManager.default
        var allBundles: [URL] = []

        for dir in applicationDirs {
            guard fileManager.fileExists(atPath: dir.path) else { continue }
            let contents = try fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            for url in contents where url.pathExtension == "app" {
                allBundles.append(url)
            }
        }

        // Deduplicate by bundle name — prefer /Applications over /System/Applications
        // Process in natural order: /Applications first, then /System/Applications
        // When a /System/Applications app has same name as /Applications, skip it
        var seen = Set<String>()
        var unique: [URL] = []
        for url in allBundles {
            let name = url.lastPathComponent
            if seen.contains(name) { continue }
            seen.insert(name)
            unique.append(url)
        }

        let appBundles = unique.filter { url in
            if showSystemApps { return true }
            return !url.path.hasPrefix("/System/Applications/")
        }

        return appBundles.map { AppItem(bundleURL: $0) }
    }
}
