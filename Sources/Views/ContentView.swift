import SwiftUI

struct ContentView: View {

    @State private var viewModel = AppsViewModel()

    var body: some View {
        GeometryReader { geometry in
            let columns = columnsFor(width: geometry.size.width)

            VStack(spacing: 0) {
                SearchBarView(searchText: $viewModel.searchText)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Scanning applications…")
                        .progressViewStyle(.circular)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else if viewModel.filteredApps.isEmpty {
                    Spacer()
                    Text("No apps found")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        AppGridView(
                            apps: viewModel.filteredApps,
                            columns: columns,
                            onLaunch: { viewModel.launchApp($0) },
                            onUninstall: { viewModel.uninstallApp($0) },
                            onRevealInFinder: { viewModel.revealInFinder($0) }
                        )
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 480, minHeight: 360)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial.opacity(0.93))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            viewModel.loadApps()
            NSApp.activate(ignoringOtherApps: true)
        }
        .onKeyPress(.escape) {
            NSApp.keyWindow?.orderOut(nil)
            return .handled
        }
    }

    private func columnsFor(width: CGFloat) -> [GridItem] {
        let count = max(3, Int((width - 48) / 104))
        return Array(repeating: GridItem(.fixed(88), spacing: 16), count: count)
    }
}
