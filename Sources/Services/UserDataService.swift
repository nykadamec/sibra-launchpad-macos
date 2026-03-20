import Foundation

final class UserDataService: @unchecked Sendable {

    static let shared = UserDataService()

    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sibraDir = appSupport.appendingPathComponent("Sibra")
        return sibraDir.appendingPathComponent("data.json")
    }()

    private let queue = DispatchQueue(label: "com.sibra.userdata", attributes: .concurrent)

    private(set) var data: UserData

    private init() {
        if let loaded = Self.load(from: fileURL) {
            self.data = loaded
        } else {
            self.data = UserData()
            self.data.categories = UserData.defaultCategories
            save()
        }
    }

    // MARK: - Load / Save

    private static func load(from url: URL) -> UserData? {
        guard FileManager.default.fileExists(atPath: url.path),
              let json = try? Data(contentsOf: url),
              let userData = try? JSONDecoder().decode(UserData.self, from: json) else {
            return nil
        }
        return userData
    }

    func save() {
        queue.async(flags: .barrier) { [data] in
            let dir = self.fileURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let json = try? JSONEncoder().encode(data)
            try? json?.write(to: self.fileURL)
        }
    }

    // MARK: - Categories

    func category(for app: AppItem) -> UserData.Category? {
        let path = app.bundleURL.path
        return data.categories.first { $0.appPaths.contains(path) }
    }

    func addApp(_ app: AppItem, to category: UserData.Category) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let path = app.bundleURL.path
            // Remove from all categories first
            for i in self.data.categories.indices {
                self.data.categories[i].appPaths.removeAll { $0 == path }
            }
            // Add to target
            if let idx = self.data.categories.firstIndex(where: { $0.id == category.id }) {
                self.data.categories[idx].appPaths.append(path)
            }
            self.save()
        }
    }

    func removeApp(_ app: AppItem, from category: UserData.Category) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let path = app.bundleURL.path
            if let idx = self.data.categories.firstIndex(where: { $0.id == category.id }) {
                self.data.categories[idx].appPaths.removeAll { $0 == path }
            }
            self.save()
        }
    }

    // MARK: - Favourites

    func isFavourite(_ app: AppItem) -> Bool {
        data.favourites.contains(app.bundleURL.path)
    }

    func toggleFavourite(_ app: AppItem) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let path = app.bundleURL.path
            if let idx = self.data.favourites.firstIndex(of: path) {
                self.data.favourites.remove(at: idx)
            } else {
                self.data.favourites.append(path)
            }
            self.save()
        }
    }

    // MARK: - Hotkeys

    func hotkey(for app: AppItem) -> String? {
        data.pinnedHotkeys[app.bundleURL.path]
    }

    func setHotkey(_ hotkey: String?, for app: AppItem) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let hk = hotkey {
                self.data.pinnedHotkeys[app.bundleURL.path] = hk
            } else {
                self.data.pinnedHotkeys.removeValue(forKey: app.bundleURL.path)
            }
            self.save()
        }
    }

    // MARK: - Settings

    func updateSettings(_ block: @escaping (inout UserData.Settings) -> Void) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            block(&self.data.settings)
            self.save()
        }
    }
}
