# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
./build.sh          # Build the app (compiles Swift via swiftc, copies resources)
open build/Sibra.app  # Run the app
```

The build script (`build.sh`) uses direct `swiftc` compilation — not Xcode or SPM. It compiles all Swift files in `Sources/` into a single binary.

Log output: `~/Library/Application Support/Sibra/logs/Sibra.log`

## Architecture

### Entry Point
- `Sources/App/main.swift` — Manual `NSApplication.shared.run()` loop (no @main)
- `Sources/App/AppDelegate.swift` — Window, menu bar, global hotkey registration

### State Management
- `UserDataStore` (singleton, `@Observable`) — Persistent state: categories, favorites, per-app hotkeys, settings. Stored as JSON at `~/Library/Application Support/Sibra/data.json`
- `AppsViewModel` (`@Observable`, `@MainActor`) — Ephemeral UI state: loaded apps list, search/filter, selected category, loading state

### Views
- SwiftUI views in `Sources/Views/`
- `ContentView.swift` — Root view, layout (sidebar + main grid)
- `SettingsView.swift` — Tabbed settings (General, Hotkeys, About); contains `HotkeyDisplayButton` for global hotkey recording
- `AppIconCardView.swift` — App card with context menu; contains `HotkeyRecorderSheet` for per-app hotkey recording

### Services
- `AppScannerService` — Scans `/Applications` for `.app` bundles
- `AppLauncherService` — Launches apps via `NSWorkspace`
- `AppUninstallerService` — Moves apps to Trash

### Utilities
- `HotkeyManager` — Global hotkey via Carbon APIs (`RegisterEventHotKey`). String format: `⌃⌥⇧⌘` + key (e.g., `⌃Space`)

### Key Patterns
- **SwiftUI + AppKit interop**: `NSHostingView` wraps SwiftUI content; `NSStatusItem` for menu bar
- **Reactive state**: `@Observable` + `@Bindable` for two-way bindings
- **Cross-component communication**: `NotificationCenter` for events like `globalHotkeyDidChange`, `SibraShowSettings`, `SibraSheetOpened/Closed`
- **Window behavior**: Floating window, hides on focus loss (except sheets), Escape key closes

## Hotkey String Format

Hotkeys are stored as strings combining modifier symbols and key:
- Modifiers: `⌃` (control), `⌥` (option), `⇧` (shift), `⌘` (command)
- Special keys: `Space`, `Return`, `Esc`, `Backspace`, `Tab`
- Example: `⌘⇧K` means Cmd+Shift+K

## Data Location

- Config: `~/Library/Application Support/Sibra/data.json`
- Logs: `~/Library/Application Support/Sibra/logs/Sibra.log`
