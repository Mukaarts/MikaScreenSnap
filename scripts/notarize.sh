#!/bin/bash
# notarize.sh — Sign with Developer ID and notarize for distribution
#
# SETUP:
# 1. Enroll in Apple Developer Program ($99/year)
# 2. Create a Developer ID Application certificate in Xcode
# 3. Generate an app-specific password at https://appleid.apple.com
# 4. Set environment variables:
#
#    export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
#    export APPLE_ID="your@email.com"
#    export TEAM_ID="YOURTEAMID"
#    export NOTARIZE_PASSWORD="xxxx-xxxx-xxxx-xxxx"
#
# 5. Run: bash scripts/notarize.sh
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/Mika+ScreenSnap.app"
INSTALLER_DIR="$PROJECT_DIR/installer"

# Validate environment
for var in DEVELOPER_ID APPLE_ID TEAM_ID NOTARIZE_PASSWORD; do
    if [ -z "${!var:-}" ]; then
        echo "ERROR: $var environment variable is not set."
        echo "See the setup instructions at the top of this script."
        exit 1
    fi
done

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: App bundle not found at $APP_BUNDLE"
    echo "Run 'bash scripts/build.sh' first."
    exit 1
fi

# Read version
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0")
DMG_NAME="Mika+ScreenSnap-v${VERSION}.dmg"
DMG_PATH="$INSTALLER_DIR/$DMG_NAME"

echo "==> Removing quarantine attributes..."
xattr -cr "$APP_BUNDLE"

echo "==> Signing embedded frameworks with Developer ID (inside-out)..."
if [ -d "$APP_BUNDLE/Contents/Frameworks" ]; then
    for fw in "$APP_BUNDLE/Contents/Frameworks/"*.framework; do
        if [ -d "$fw" ]; then
            echo "    Signing: $(basename "$fw")"
            codesign --force --sign "$DEVELOPER_ID" --options runtime "$fw"
        fi
    done
fi

echo "==> Signing app bundle with Developer ID..."
codesign --force --sign "$DEVELOPER_ID" \
    --entitlements "$PROJECT_DIR/Resources/MikaScreenSnap.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

echo "==> Verifying signature..."
codesign --verify --deep --strict "$APP_BUNDLE"

echo "==> Creating DMG for notarization..."
mkdir -p "$INSTALLER_DIR"
STAGING_DIR=$(mktemp -d)
trap "rm -rf '$STAGING_DIR'" EXIT

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "Mika+ScreenSnap" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "==> Signing DMG..."
codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"

echo "==> Submitting for notarization (this may take a few minutes)..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$NOTARIZE_PASSWORD" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo ""
echo "==> Done! Notarized DMG: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "This DMG can be distributed outside the App Store."
echo ""
