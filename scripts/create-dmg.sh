#!/bin/bash
# create-dmg.sh — Create professional DMG installer with custom background
# Requires: brew install create-dmg
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/Mika+ScreenSnap.app"
INSTALLER_DIR="$PROJECT_DIR/installer"

# Check prerequisites
if ! command -v create-dmg &>/dev/null; then
    echo "ERROR: 'create-dmg' is not installed."
    echo ""
    echo "Install it with Homebrew:"
    echo "  brew install create-dmg"
    echo ""
    echo "Or use the simple fallback script:"
    echo "  bash scripts/create-dmg-simple.sh"
    exit 1
fi

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: App bundle not found at $APP_BUNDLE"
    echo "Run 'bash scripts/build.sh' first."
    exit 1
fi

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0")
DMG_NAME="Mika+ScreenSnap-v${VERSION}.dmg"
DMG_PATH="$INSTALLER_DIR/$DMG_NAME"

# Generate background if missing
if [ ! -f "$INSTALLER_DIR/dmg-background.png" ]; then
    echo "==> Generating DMG background..."
    cd "$PROJECT_DIR"
    swift scripts/GenerateDMGBackground.swift
fi

# Remove existing DMG
rm -f "$DMG_PATH"

mkdir -p "$INSTALLER_DIR"

echo "==> Creating DMG: $DMG_NAME"

# Build DMG args
DMG_ARGS=(
    --volname "Mika+ScreenSnap"
    --window-size 600 400
    --icon-size 128
    --icon "Mika+ScreenSnap.app" 150 200
    --app-drop-link 450 200
    --hide-extension "Mika+ScreenSnap.app"
    "$DMG_PATH"
    "$APP_BUNDLE"
)

# Add volume icon if available
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    DMG_ARGS=("--volicon" "$PROJECT_DIR/Resources/AppIcon.icns" "${DMG_ARGS[@]}")
fi

# Add background if available
if [ -f "$INSTALLER_DIR/dmg-background@2x.png" ]; then
    DMG_ARGS=("--background" "$INSTALLER_DIR/dmg-background@2x.png" "${DMG_ARGS[@]}")
elif [ -f "$INSTALLER_DIR/dmg-background.png" ]; then
    DMG_ARGS=("--background" "$INSTALLER_DIR/dmg-background.png" "${DMG_ARGS[@]}")
fi

create-dmg "${DMG_ARGS[@]}"

echo ""
echo "==> DMG created: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
