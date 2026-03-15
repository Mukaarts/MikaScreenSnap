#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Mika+ScreenSnap"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Parse flags
CLEAN=false
for arg in "$@"; do
    case "$arg" in
        --clean) CLEAN=true ;;
    esac
done

if [ "$CLEAN" = true ]; then
    echo "==> Cleaning .build/ directory..."
    rm -rf "$PROJECT_DIR/.build"
fi

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

# Embed Sparkle.framework if available
SPARKLE_FW=$(find "$PROJECT_DIR/.build/artifacts" -path "*/macos-arm64_x86_64/Sparkle.framework" -print -quit 2>/dev/null || true)
if [ -z "$SPARKLE_FW" ]; then
    SPARKLE_FW=$(find "$PROJECT_DIR/.build/artifacts" -name "Sparkle.framework" -print -quit 2>/dev/null || true)
fi
if [ -n "$SPARKLE_FW" ]; then
    echo "==> Embedding Sparkle.framework..."
    mkdir -p "$APP_BUNDLE/Contents/Frameworks"
    cp -R "$SPARKLE_FW" "$APP_BUNDLE/Contents/Frameworks/"

    # Add @executable_path/../Frameworks to rpath so dyld finds Sparkle
    install_name_tool -add_rpath "@executable_path/../Frameworks" \
        "$APP_BUNDLE/Contents/MacOS/MikaScreenSnap" 2>/dev/null || true

    # Sign all nested Sparkle components inside-out (must match app's ad-hoc identity)
    SPARKLE_DIR="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
    for xpc in "$SPARKLE_DIR"/Versions/B/XPCServices/*.xpc; do
        [ -d "$xpc" ] && codesign --force --sign - --options runtime "$xpc"
    done
    for app in "$SPARKLE_DIR"/Versions/B/*.app; do
        [ -d "$app" ] && codesign --force --sign - --options runtime "$app"
    done
    codesign --force --sign - --options runtime "$SPARKLE_DIR/Versions/B/Autoupdate" 2>/dev/null || true
    codesign --force --sign - --options runtime "$SPARKLE_DIR"
fi

echo "==> Signing with hardened runtime..."
codesign --force --sign - \
    --entitlements "$PROJECT_DIR/Resources/MikaScreenSnap.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0")

echo ""
echo "==> Build complete: $APP_BUNDLE (v$VERSION)"
echo ""
echo "To verify signature:"
echo "  codesign --verify --deep --strict \"$APP_BUNDLE\""
echo ""
echo "To run:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "To create DMG:"
echo "  bash scripts/create-dmg.sh"
echo ""
