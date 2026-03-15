#!/bin/bash
# create-dmg-simple.sh — Create DMG with background and layout using only macOS built-in tools
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/Mika+ScreenSnap.app"
INSTALLER_DIR="$PROJECT_DIR/installer"
APP_NAME="Mika+ScreenSnap"
VOL_NAME="Mika+ScreenSnap"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: App bundle not found at $APP_BUNDLE"
    echo "Run 'bash scripts/build.sh' first."
    exit 1
fi

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0")
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
DMG_PATH="$INSTALLER_DIR/$DMG_NAME"
DMG_TEMP="$INSTALLER_DIR/${APP_NAME}-temp.dmg"

mkdir -p "$INSTALLER_DIR"

# Generate background if missing
BG_IMAGE="$INSTALLER_DIR/dmg-background@2x.png"
if [ ! -f "$BG_IMAGE" ]; then
    echo "==> Generating DMG background..."
    cd "$PROJECT_DIR"
    swift scripts/GenerateDMGBackground.swift
fi

# Clean up previous files
rm -f "$DMG_PATH" "$DMG_TEMP"

# Calculate DMG size (app size + 20MB headroom)
APP_SIZE_KB=$(du -sk "$APP_BUNDLE" | cut -f1)
DMG_SIZE_KB=$((APP_SIZE_KB + 20480))

echo "==> Creating writable DMG..."
hdiutil create \
    -size "${DMG_SIZE_KB}k" \
    -volname "$VOL_NAME" \
    -fs HFS+ \
    -type SPARSE \
    "$DMG_TEMP"

# Mount the writable DMG
echo "==> Mounting..."
MOUNT_OUTPUT=$(hdiutil attach "${DMG_TEMP}.sparseimage" -readwrite -noverify -noautoopen)
MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')

echo "    Mounted at: $MOUNT_POINT"

# Copy app and create Applications link
echo "==> Copying app bundle..."
cp -R "$APP_BUNDLE" "$MOUNT_POINT/"
ln -s /Applications "$MOUNT_POINT/Applications"

# Copy background image into a hidden folder on the DMG
if [ -f "$BG_IMAGE" ]; then
    echo "==> Setting background image..."
    mkdir -p "$MOUNT_POINT/.background"
    cp "$BG_IMAGE" "$MOUNT_POINT/.background/background.png"
fi

# Set volume icon if available
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$MOUNT_POINT/.VolumeIcon.icns"
    SetFile -a C "$MOUNT_POINT" 2>/dev/null || true
fi

# Use AppleScript to set Finder view options
echo "==> Configuring Finder layout..."
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        delay 1

        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false

        set the bounds of container window to {100, 100, 700, 500}

        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128

        try
            set background picture of viewOptions to file ".background:background.png"
        end try

        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}

        close
        open
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Make sure Finder writes the .DS_Store
sync

echo "==> Unmounting..."
hdiutil detach "$MOUNT_POINT" -quiet

echo "==> Converting to compressed DMG..."
hdiutil convert "${DMG_TEMP}.sparseimage" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Clean up temp
rm -f "${DMG_TEMP}.sparseimage"

echo ""
echo "==> DMG created: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
