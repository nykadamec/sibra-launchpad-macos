#!/bin/bash
set -e

APP_NAME="Sibra"
OUT_DIR="build"
APP_DIR="$OUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🧹 Cleaning old build..."
rm -rf "$OUT_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "🔨 Compiling Swift sources..."
swiftc \
    Sources/App/main.swift \
    Sources/App/AppDelegate.swift \
    Sources/Utilities/Logger.swift \
    Sources/Models/UserData.swift \
    Sources/Models/AppItem.swift \
    Sources/Services/AppScannerService.swift \
    Sources/Services/AppLauncherService.swift \
    Sources/Services/AppUninstallerService.swift \
    Sources/Utilities/HotkeyManager.swift \
    Sources/ViewModels/AppsViewModel.swift \
    Sources/Views/ContentView.swift \
    Sources/Views/CategorySidebarView.swift \
    Sources/Views/FavouritesRowView.swift \
    Sources/Views/AppGridView.swift \
    Sources/Views/AppIconCardView.swift \
    Sources/Views/SearchBarView.swift \
    Sources/Views/SettingsView.swift \
    -o "$MACOS_DIR/$APP_NAME" \
    -target arm64-apple-macosx14.0 \
    -swift-version 6 \
    -framework SwiftUI \
    -framework AppKit \
    -framework Carbon \
    -framework Foundation

echo "📋 Copying resources..."
cp Resources/Info.plist "$CONTENTS_DIR/"
cp Resources/Sibra.entitlements "$CONTENTS_DIR/"

# Create launch helper
cat > "$OUT_DIR/run_sibra.sh" << 'RUNSCRIPT'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
open "$DIR/Sibra.app"
echo "Log: /tmp/Sibra.log"
echo "View log: tail -f /tmp/Sibra.log"
RUNSCRIPT
chmod +x "$OUT_DIR/run_sibra.sh"
cp Resources/Sibra.entitlements "$CONTENTS_DIR/Sibra.entitlements"

# Create launch script
cat > "$OUT_DIR/run_sibra.sh" << 'RUNSCRIPT'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
open "$DIR/Sibra.app"
echo "Log: ~/Library/Application Support/Sibra/logs/Sibra.log"
echo "View log: tail -f ~/Library/Application\ Support/Sibra/logs/Sibra.log"
RUNSCRIPT
chmod +x "$OUT_DIR/run_sibra.sh"

echo "✅ Build complete: $APP_DIR"
echo "🚀 Run via: open $APP_DIR"
echo "   Or:      $OUT_DIR/run_sibra.sh"
echo "   Log:     ~/Library/Application Support/Sibra/logs/Sibra.log"
