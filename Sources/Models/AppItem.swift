import Foundation
import AppKit

struct AppItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let bundleURL: URL

    var icon: NSImage {
        let wsIcon = NSWorkspace.shared.icon(forFile: bundleURL.path)
        wsIcon.size = NSSize(width: 64, height: 64)
        return wsIcon
    }

    init(bundleURL: URL) {
        self.id = UUID()
        self.bundleURL = bundleURL
        self.name = bundleURL.deletingPathExtension().lastPathComponent
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleURL)
    }

    static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        lhs.bundleURL == rhs.bundleURL
    }
}
