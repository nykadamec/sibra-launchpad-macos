import SwiftUI
import AppKit

struct OnboardingContentView: View {
    let onComplete: () -> Void

    @State private var showOnboarding = true

    var body: some View {
        OnboardingView(isPresented: $showOnboarding, onComplete: onComplete)
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var isHoveringClose = false
    private let totalPages = 3

    var body: some View {
        ZStack {
            // Glass panel background
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)

            // Panel content — inside rounded rect
            VStack(spacing: 0) {
                // Close button — top right corner of panel
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                            .opacity(isHoveringClose ? 0.7 : 1.0)
                            .scaleEffect(isHoveringClose ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isHoveringClose)
                    }
                    .buttonStyle(.plain)
                    .sibraCursor(.pointingHand)
                    .onHover { hovering in
                        isHoveringClose = hovering
                    }
                }
                .padding(.top, 12)

                Spacer()

                // Page content
                ZStack {
                    welcomePage.opacity(currentPage == 0 ? 1 : 0)
                    hotkeyPage.opacity(currentPage == 1 ? 1 : 0)
                    donePage.opacity(currentPage == 2 ? 1 : 0)
                }
                .animation(.easeInOut(duration: 0.25), value: currentPage)

                Spacer()

                // Page indicator — centered at bottom
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(width: 420, height: 380)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, value: currentPage)

            VStack(spacing: 8) {
                Text("Welcome to Sibra")
                    .font(.system(size: 24, weight: .bold))

                Text("Your minimalist app launcher.\nBrowse, launch, and organize your apps with ease.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    withAnimation { currentPage = 1 }
                } label: {
                    Text("Next")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 36)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .sibraCursor(.pointingHand)
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private var hotkeyPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "keyboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .symbolEffect(.bounce, value: currentPage)

            VStack(spacing: 8) {
                Text("Global Hotkey")
                    .font(.system(size: 24, weight: .bold))

                Text("Press **⌃ Space** to toggle Sibra\nfrom anywhere on your Mac.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Hotkey display
            HStack(spacing: 8) {
                HotkeyKeyView(symbol: "control")
                HotkeyKeyView(symbol: "space")
            }
            .padding(.vertical, 8)

            Text("Configure in Settings → Hotkeys")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    withAnimation { currentPage = 0 }
                } label: {
                    Text("Back")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 80, height: 36)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .sibraCursor(.pointingHand)

                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Next")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 36)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .sibraCursor(.pointingHand)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private var donePage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: currentPage)

            VStack(spacing: 8) {
                Text("You're All Set")
                    .font(.system(size: 24, weight: .bold))

                Text("Explore your apps, set up categories,\nand make Sibra truly yours.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    withAnimation { currentPage = 1 }
                } label: {
                    Text("Back")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 80, height: 36)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .sibraCursor(.pointingHand)

                Button {
                    complete()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 36)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .sibraCursor(.pointingHand)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Actions

    private func dismiss() {
        complete()
    }

    private func complete() {
        onComplete()
        isPresented = false
    }
}

struct HotkeyKeyView: View {
    let symbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )

            if symbol == "control" {
                Text("⌃")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: "space")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
    }
}
