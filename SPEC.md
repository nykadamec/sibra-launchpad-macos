# Sibra — macOS App Launcher & Manager

## 1. Project Overview

- **Name:** Sibra
- **Type:** Native macOS application
- **Core functionality:** A minimalist app launcher and manager inspired by Launchpad — displays installed apps in a grid, supports launching and uninstalling.
- **Target:** macOS 13+ (Ventura and later)
- **Architecture:** MVVM with SwiftUI

---

## 2. UI/UX Specification

### Window Model
- **Main window:** Single floating window, borderless, rounded corners (16pt), glass material background
- **Window size:** 720×520 pt, resizable, min 480×360
- **Window position:** Centered on active screen on launch
- **Dismissal:** Click outside window, press Escape, or global hotkey

### Visual Design

#### Color Palette
| Role | Light | Dark |
|------|-------|------|
| Background | `NSVisualEffectView.material == .hudWindow` | Same |
| Card background | `Color.white.opacity(0.5)` | `Color.black.opacity(0.3)` |
| Card hover | `Color.blue.opacity(0.12)` | `Color.blue.opacity(0.2)` |
| Icon tint | System primary | System primary |
| Text primary | `.primary` (system) | `.primary` |
| Text secondary | `.secondary` | `.secondary` |
| Search bar bg | `Color.black.opacity(0.06)` | `Color.white.opacity(0.08)` |

#### Typography
- **App name:** SF Pro Text, 11pt, medium weight, centered below icon
- **Search field:** SF Pro Text, 14pt, regular
- **Context menu:** SF Pro Text, 13pt

#### Spacing System (8pt grid)
- Grid item size: 88×88 pt (icon 64×64 + 8pt label area)
- Grid spacing: 16pt horizontal, 12pt vertical
- Content padding: 24pt
- Search bar height: 36pt, corner radius 8pt

#### macOS-Specific
- Vibrancy via `NSVisualEffectView` (`.hudWindow` material)
- Drag & drop support for app icons
- Right-click context menu per app

### Views & Components

1. **`ContentView`** — Root SwiftUI view, holds search bar + grid
2. **`AppGridView`** — LazyVGrid of `AppIconCardView`, handles keyboard nav
3. **`AppIconCardView`** — Glass card with app icon + name, hover/drag states
4. **`SearchBarView`** — Search field with magnifying glass icon, clears button
5. **`AppContextMenu`** — Right-click menu: Open, Uninstall, Reveal in Finder

### View States
- **Default:** Grid of app cards
- **Hover:** Card highlights with blue tint
- **Loading:** ProgressView spinner while scanning `/Applications`
- **Empty (no results):** Centered message "No apps found"
- **Uninstall confirmation:** Native `NSAlert` dialog

---

## 3. Functionality Specification

### Core Features (priority order)

1. **App Scanning** — Read all `.app` bundles from `/Applications` on launch and on demand
2. **App Grid Display** — Show icons in responsive grid, sorted alphabetically
3. **Search/Filter** — Real-time filter by app name as user types
4. **App Launching** — Double-click or ⌘↵ to open app via `NSWorkspace.shared.openApplication(at:configuration:)`
5. **App Uninstallation** — Right-click → Uninstall → Move to Trash via Finder AppleScript
6. **Reveal in Finder** — Right-click → Reveal in Finder
7. **Global Hotkey** — ⌘Space to toggle Sibra window (requires Accessibility permission)
8. **Menu Bar Icon** — Status bar item with dropdown (Show / Quit)
9. **Keyboard Navigation** — Arrow keys to move, Enter to launch, Escape to close

### Data Flow
```
AppScannerService (reads /Applications)
        ↓
  [AppItem model]
        ↓
  AppsViewModel (@Published apps, searchText)
        ↓
  AppGridView (SwiftUI)
```

### Error Handling
- App bundle missing icon → use system generic app icon
- App can't be opened → show alert with error message
- Uninstall fails → show alert

---

## 4. Technical Specification

### Dependencies
- **None** — Pure Apple frameworks only (SwiftUI, AppKit, Foundation, Carbon for hotkey)

### Frameworks Used
- `SwiftUI` — UI
- `AppKit` — NSWorkspace, NSVisualEffectView, NSAlert, NSStatusItem
- `Foundation` — FileManager, Bundle
- `Carbon` — RegisterEventHotKey for global hotkey
- `Combine` — Reactive bindings in ViewModel

### Asset Requirements
- App icon (1024×1024 for App Store, will use generic for now)
- Menu bar icon (18×18 template image, SF Symbol: `square.grid.2x2`)

### File Structure
```
Sources/
├── App/
│   ├── main.swift              # Manual NSApplication entry point
│   └── SibraApp.swift          # @main AppKit app delegate
├── Models/
│   └── AppItem.swift           # App data model
├── Services/
│   ├── AppScannerService.swift # Scans /Applications
│   ├── AppLauncherService.swift # Opens apps via NSWorkspace
│   └── AppUninstallerService.swift # Moves to Trash
├── ViewModels/
│   └── AppsViewModel.swift     # @Observable, drives the UI
├── Views/
│   ├── ContentView.swift       # Root view
│   ├── AppGridView.swift       # Grid layout
│   ├── AppIconCardView.swift   # Individual app card
│   └── SearchBarView.swift     # Search input
├── Utilities/
│   └── HotkeyManager.swift     # Global ⌘Space hotkey via Carbon
└── SibraApp/
    └── SibraApp.swift          # Shared @main标的
```

---

## 5. Implementation Notes

- Use `@Observable` macro (iOS 17/macOS 14+ Swift)
- `AppScannerService` runs async on background queue
- App icons loaded via `NSWorkspace.shared.icon(forFile:)`
- Global hotkey uses Carbon `RegisterEventHotKey` + `CGSSetSystemHotKeyOperating`
- Window configured as `.borderless`, `.fullSizeContentView`, `.nonactivatingPanel` for Spotlight-like feel
