#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Mika+ScreenSnap"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "==> Building MikaScreenSnap..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

EXECUTABLE=$(swift build -c release --show-bin-path)/MikaScreenSnap

echo "==> Assembling app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/MikaScreenSnap"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy app icon and menubar icon
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
for img in MenubarIconTemplate.png MenubarIconTemplate@2x.png; do
    if [ -f "$PROJECT_DIR/Resources/$img" ]; then
        cp "$PROJECT_DIR/Resources/$img" "$APP_BUNDLE/Contents/Resources/$img"
    fi
done

echo "==> Signing with hardened runtime..."
codesign --force --sign - \
    --entitlements "$PROJECT_DIR/Resources/MikaScreenSnap.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

echo ""
echo "==> Build complete: $APP_BUNDLE"
echo ""
echo "To verify signature:"
echo "  codesign --verify --deep --strict \"$APP_BUNDLE\""
echo ""
echo "To run:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "To install:"
echo "  cp -r \"$APP_BUNDLE\" /Applications/"
