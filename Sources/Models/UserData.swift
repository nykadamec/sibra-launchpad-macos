import Foundation

@Observable
class UserDataStore: @unchecked Sendable {
    static let shared = UserDataStore()

    var categories: [Category] = []
    var pinnedHotkeys: [String: String] = [:]
    var favourites: [String] = []
    var settings = Settings()

    struct Category: Codable, Identifiable, Hashable {
        let id: UUID
        var name: String
        var appPaths: [String]

        init(name: String, appPaths: [String] = []) {
            self.id = UUID()
            self.name = name
            self.appPaths = appPaths
        }
    }

    struct Settings: Codable, Equatable {
        var categoriesEnabled: Bool = true
        var showSystemApps: Bool = false
        var launchAnimation: Bool = true
        var hotkeysEnabled: Bool = true
        var displayMode: DisplayMode = .windowed
        var globalHotkey: String = "⌃Space"

        enum DisplayMode: String, Codable, Equatable {
            case windowed
            case fullscreen
        }
    }

    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sibraDir = appSupport.appendingPathComponent("Sibra")
        return sibraDir.appendingPathComponent("data.json")
    }()

    private init() {
        categories = UserDataStore.defaultCategories
        load()
    }

    private func load() {
        guard let json = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(DataFile.self, from: json) else { return }
        categories = decoded.categories
        pinnedHotkeys = decoded.pinnedHotkeys
        favourites = decoded.favourites
        settings = decoded.settings
    }

    func save() {
        let dataFile = DataFile(
            categories: categories,
            pinnedHotkeys: pinnedHotkeys,
            favourites: favourites,
            settings: settings
        )
        guard let json = try? JSONEncoder().encode(dataFile) else { return }
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? json.write(to: fileURL)
    }

    static let defaultCategories: [Category] = [
        Category(name: "Social"),
        Category(name: "Dev"),
        Category(name: "Games"),
        Category(name: "Media"),
        Category(name: "Other")
    ]

    private struct DataFile: Codable {
        let categories: [Category]
        let pinnedHotkeys: [String: String]
        let favourites: [String]
        let settings: Settings
    }

    // MARK: - Categories

    func category(for app: AppItem) -> Category? {
        let path = app.bundleURL.path
        return categories.first { $0.appPaths.contains(path) }
    }

    func addApp(_ app: AppItem, to category: Category) {
        let path = app.bundleURL.path
        for i in categories.indices {
            categories[i].appPaths.removeAll { $0 == path }
        }
        if let idx = categories.firstIndex(where: { $0.id == category.id }) {
            categories[idx].appPaths.append(path)
        }
        save()
    }

    func removeApp(_ app: AppItem, from category: Category) {
        let path = app.bundleURL.path
        if let idx = categories.firstIndex(where: { $0.id == category.id }) {
            categories[idx].appPaths.removeAll { $0 == path }
        }
        save()
    }

    // MARK: - Favourites

    func isFavourite(_ app: AppItem) -> Bool {
        favourites.contains(app.bundleURL.path)
    }

    func toggleFavourite(_ app: AppItem) {
        let path = app.bundleURL.path
        if let idx = favourites.firstIndex(of: path) {
            favourites.remove(at: idx)
        } else {
            favourites.append(path)
        }
        save()
    }

    // MARK: - Hotkeys

    func hotkey(for app: AppItem) -> String? {
        pinnedHotkeys[app.bundleURL.path]
    }

    func setHotkey(_ hotkey: String?, for app: AppItem) {
        if let hk = hotkey {
            pinnedHotkeys[app.bundleURL.path] = hk
        } else {
            pinnedHotkeys.removeValue(forKey: app.bundleURL.path)
        }
        save()
    }

    func addCategory(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Avoid duplicates
        guard !categories.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else { return }
        categories.append(Category(name: trimmed))
        save()
    }

    func removeCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
        save()
    }
}
