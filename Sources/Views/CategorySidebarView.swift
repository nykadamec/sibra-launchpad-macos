import SwiftUI

struct CategorySidebarView: View {

    let categories: [UserDataStore.Category]
    @Binding var selectedCategory: UserDataStore.Category?
    let appCount: Int

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
                isSelected: selectedCategory == nil
            ) {
                selectedCategory = nil
            }
            .padding(.horizontal, 8)

            Divider()
                .padding(.vertical, 6)
                .padding(.horizontal, 16)

            // Categories
            ForEach(categories) { category in
                CategoryRowView(
                    icon: iconFor(category.name),
                    name: category.name,
                    count: category.appPaths.count,
                    isSelected: selectedCategory?.id == category.id
                ) {
                    selectedCategory = category
                }
                .padding(.horizontal, 8)
                .contextMenu {
                    Button("Remove Category", role: .destructive) {
                        // TODO: remove category
                    }
                }
            }

            Spacer()

            // Add category button
            Button {
                // TODO: add new category
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                    Text("Add Category")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 160, alignment: .leading)
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
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.15))
                }
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}
