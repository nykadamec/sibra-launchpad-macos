import Foundation
import AppKit

struct AppItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let bundleURL: URL
    let icon: NSImage

    init(bundleURL: URL) {
        self.id = UUID()
        self.bundleURL = bundleURL
        self.name = Self.extractName(from: bundleURL)
        self.icon = Self.loadIcon(for: bundleURL)
    }

    private static func extractName(from url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    private static func loadIcon(for bundleURL: URL) -> NSImage {
        let wsIcon = NSWorkspace.shared.icon(forFile: bundleURL.path)
        wsIcon.size = NSSize(width: 64, height: 64)
        return wsIcon
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleURL)
    }

    static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        lhs.bundleURL == rhs.bundleURL
    }
}
