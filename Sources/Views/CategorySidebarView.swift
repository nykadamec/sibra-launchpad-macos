import SwiftUI

struct CategorySidebarView: View {

    let categories: [UserDataStore.Category]
    @Binding var selectedCategory: UserDataStore.Category?
    let appCount: Int
    let onAppDropped: (AppItem, UserDataStore.Category) -> Void
    let allApps: () -> [AppItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sibra")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // All apps
            CategoryRowView(
                icon: "square.grid.2x2",
                name: "All",
                count: appCount,
                isSelected: selectedCategory == nil,
                isDropTarget: false,
                onDrop: nil
            ) {
                selectedCategory = nil
            }
            .padding(.horizontal, 8)

            Divider()
                .padding(.vertical, 6)
                .padding(.horizontal, 16)

            // Categories
            ForEach(categories) { category in
                DroppableCategoryRow(
                    category: category,
                    isSelected: selectedCategory?.id == category.id,
                    onSelect: { selectedCategory = category },
                    onDrop: { providers in
                        handleDrop(providers: providers, category: category)
                    }
                )
                .padding(.horizontal, 8)
            }

            Spacer()
        }
        .frame(width: 160, alignment: .leading)
    }

    private func handleDrop(providers: [NSItemProvider], category: UserDataStore.Category) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { data, _ in
            guard let data = data as? Data,
                  let path = String(data: data, encoding: .utf8),
                  let app = allApps().first(where: { $0.bundleURL.path == path }) else { return }

            DispatchQueue.main.async {
                onAppDropped(app, category)
            }
        }

        return true
    }
}

// Separate component so each row has its own @State
struct DroppableCategoryRow: View {

    let category: UserDataStore.Category
    let isSelected: Bool
    let onSelect: () -> Void
    let onDrop: ([NSItemProvider]) -> Bool

    @State private var isTargeted = false

    var body: some View {
        CategoryRowView(
            icon: iconFor(category.name),
            name: category.name,
            count: category.appPaths.count,
            isSelected: isSelected,
            isDropTarget: isTargeted,
            onDrop: nil
        ) {
            onSelect()
        }
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            onDrop(providers)
        }
    }

    private func iconFor(_ name: String) -> String {
        switch name.lowercased() {
        case "social": return "bubble.left.and.bubble.right"
        case "dev": return "chevron.left.forwardslash.chevron.right"
        case "games": return "gamecontroller"
        case "media": return "music.note.tv"
        default: return "folder"
        }
    }
}

struct CategoryRowView: View {

    let icon: String
    let name: String
    let count: Int
    let isSelected: Bool
    let isDropTarget: Bool
    let onDrop: (([NSItemProvider]) -> Bool)?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                Text(name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if isDropTarget {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.35))
                } else if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.15))
                }
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}
