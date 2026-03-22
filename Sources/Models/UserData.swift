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
        enum WindowSize: String, Codable, CaseIterable {
            case small
            case normal
            case big

            var size: CGSize {
                switch self {
                case .small: return CGSize(width: 600, height: 420)
                case .normal: return CGSize(width: 800, height: 560)
                case .big: return CGSize(width: 1000, height: 700)
                }
            }
        }
        
        enum IconScale: String, Codable, CaseIterable {
            case small
            case normal
            case big
            
            var iconSize: CGFloat {
                switch self {
                case .small: return 48
                case .normal: return 64
                case .big: return 80
                }
            }
            
            var cardWidth: CGFloat {
                switch self {
                case .small: return 68
                case .normal: return 88
                case .big: return 108
                }
            }
            
            var cardHeight: CGFloat {
                switch self {
                case .small: return 80
                case .normal: return 100
                case .big: return 120
                }
            }
        }

        var categoriesEnabled: Bool = true
        var showSystemApps: Bool = false
        var launchAnimation: Bool = true
        var hotkeysEnabled: Bool = true
        var globalHotkey: String = "⌃Space"
        var windowOpacity: Double = 0.9
        var windowSize: WindowSize = .normal
        var iconScale: IconScale = .normal

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            categoriesEnabled = try container.decodeIfPresent(Bool.self, forKey: .categoriesEnabled) ?? true
            showSystemApps = try container.decodeIfPresent(Bool.self, forKey: .showSystemApps) ?? false
            launchAnimation = try container.decodeIfPresent(Bool.self, forKey: .launchAnimation) ?? true
            hotkeysEnabled = try container.decodeIfPresent(Bool.self, forKey: .hotkeysEnabled) ?? true
            globalHotkey = try container.decodeIfPresent(String.self, forKey: .globalHotkey) ?? "⌃Space"
            windowOpacity = try container.decodeIfPresent(Double.self, forKey: .windowOpacity) ?? 0.9
            windowSize = try container.decodeIfPresent(WindowSize.self, forKey: .windowSize) ?? .normal
            iconScale = try container.decodeIfPresent(IconScale.self, forKey: .iconScale) ?? .normal
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
