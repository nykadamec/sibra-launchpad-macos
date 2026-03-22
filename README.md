# Sibra
### A fast, beautiful app launcher for macOS

## What is Sibra?

Sibra is a lightweight app launcher that lives in your menu bar — no Dock icon, no clutter. Press **⌃ Space** to bring up a gorgeous glass-styled window, find any app in milliseconds, and get back to work.

It's the app launcher you wish macOS Spotlight was — focused, fast, and beautiful.

---

## Why Sibra?

Most app launchers try to do too much. Sibra does one thing exceptionally well.

### ⚡ Instant Access
Press **⌃ Space** from anywhere on your Mac. Sibra pops up, you type, you launch. Gone in a flash.

### 🎨 Beautiful by Default
A frosted glass interface that looks right at home on your Mac. Supports light and dark mode, automatically.

### 📁 Works With Your Apps
Sibra reads everything in `/Applications` — no setup, no manual adding apps. Your whole library is there the moment you launch it.

### 🗂 Stay Organized
Drag apps into categories. Pin your favorites. Everything stays exactly where you put it.

### 🔒 Privacy First
Sibra runs entirely offline. No telemetry, no tracking, no accounts. Your data stays on your Mac.

---

## Getting Started

### Build from Source

```bash
git clone https://github.com/your-org/sibra.git
cd sibra
./build.sh
```

Then open `build/Sibra.app` from Finder.

### First Launch

On first launch you'll see a quick 3-step guide explaining the global hotkey. That's it — no account, no setup.

To reset the guide later:

```bash
./reset-onboarding.sh
```

---

## How to Use

**Show the window** — Press `⌃ Space` from any app  
**Launch an app** — Click it or use `↑ ↓ ← →` to navigate, then `Enter`  
**Search** — Just start typing — no need to click the search bar  
**Close the window** — Press `Escape` or click anywhere outside  

### Right-Click Any App

| Action | What It Does |
|--------|-------------|
| **Open** | Launch the app |
| **Reveal in Finder** | Show the app file in Finder |
| **Uninstall** | Move to Trash |
| **Favourite** | Pin to the top row |

---

## Settings

Open Settings via the ⚙️ button in the top-right corner or through the menu bar icon.

**Window Opacity** — Drag the slider to adjust transparency  
**Icon Size** — Small, Normal, or Big  
**Theme** — System, Light, or Dark  
**Categories** — Toggle the sidebar  
**Show System Apps** — Include macOS built-in apps  
**Global Hotkey** — Customize the shortcut that shows the window  

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌃ Space` | Toggle Sibra (works globally) |
| `↑ ↓ ← →` | Navigate the app grid |
| `Enter` | Launch selected app |
| `Escape` | Hide the window |
| `⌘ Enter` | Reveal selected app in Finder |

---

## Requirements

- **macOS 14.0+** (Sonoma or later)  
- **Arm64 or Intel Mac**

---

## Permissions

On first use of the global hotkey, macOS will ask you to grant **Accessibility** permission. This is required to register keyboard shortcuts system-wide. Go to **System Settings → Privacy & Security → Accessibility** and enable Sibra.

---

## Your Data

All settings, categories, and favourites are stored locally:

```
~/Library/Application Support/Sibra/data.json
```

Nothing is sent anywhere. Ever.

---

## Built With

- **Swift 6** + **SwiftUI** + **AppKit**
- **Carbon API** for global hotkey registration
- Zero third-party dependencies

---

## License

MIT
