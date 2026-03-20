import Foundation

struct UserData: Codable {
    var categories: [Category]
    var pinnedHotkeys: [String: String]  // bundleURL.path -> hotkey string
    var favourites: [String]               // bundleURL.paths
    var settings: Settings

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

    struct Settings: Codable {
        var categoriesEnabled: Bool = true
        var launchAnimation: Bool = true
        var hotkeysEnabled: Bool = true
    }

    init() {
        self.categories = []
        self.pinnedHotkeys = [:]
        self.favourites = []
        self.settings = Settings()
    }

    static let defaultCategories: [Category] = [
        Category(name: "Social"),
        Category(name: "Dev"),
        Category(name: "Games"),
        Category(name: "Media"),
        Category(name: "Other")
    ]
}
