#!/bin/bash
# notarize.sh — Sign with Developer ID and notarize for distribution
#
# SETUP (once):
# 1. Enroll in Apple Developer Program ($99/year)
# 2. Create a Developer ID Application certificate in Xcode
# 3. Generate an app-specific password at https://appleid.apple.com
# 4. Store it in the keychain — the password is entered interactively and never
#    has to appear in a command line or environment variable again:
#
#    xcrun notarytool store-credentials "MikaScreenSnap" \
#        --apple-id "your@email.com" --team-id "YOURTEAMID"
#
# Then just run: bash scripts/notarize.sh
#
# Override NOTARY_PROFILE to use a different keychain profile, or DEVELOPER_ID to
# pick a specific certificate when several are installed.
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/Mika+ScreenSnap.app"
INSTALLER_DIR="$PROJECT_DIR/installer"
NOTARY_PROFILE="${NOTARY_PROFILE:-MikaScreenSnap}"

# Fall back to the single installed Developer ID certificate.
if [ -z "${DEVELOPER_ID:-}" ]; then
    DEVELOPER_ID=$(security find-identity -v -p codesigning \
        | grep "Developer ID Application" \
        | head -1 \
        | sed -E 's/.*"(.*)".*/\1/')
    if [ -z "$DEVELOPER_ID" ]; then
        echo "ERROR: No 'Developer ID Application' certificate found in the keychain."
        echo "Create one in Xcode > Settings > Accounts > Manage Certificates."
        exit 1
    fi
    echo "==> Using certificate: $DEVELOPER_ID"
fi

# notarytool's keychain items are not reliably discoverable with
# `security find-generic-password`, so verify the profile by using it. This also
# catches a revoked or expired app-specific password, which a lookup would not —
# worth one network round trip before we start re-signing anything.
echo "==> Verifying notarization credentials..."
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" &>/dev/null; then
    echo "ERROR: notarytool keychain profile '$NOTARY_PROFILE' is missing or invalid."
    echo ""
    echo "Create it once — the app-specific password is prompted for, not passed in:"
    echo "  xcrun notarytool store-credentials \"$NOTARY_PROFILE\" \\"
    echo "      --apple-id \"your@email.com\" --team-id \"YOURTEAMID\""
    echo ""
    echo "Generate the app-specific password at https://appleid.apple.com"
    exit 1
fi

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
# Sparkle nests XPC services and a helper app inside the framework. Signing only the
# framework leaves those on build.sh's ad-hoc signature, which notarization rejects.
SPARKLE_DIR="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE_DIR" ]; then
    for xpc in "$SPARKLE_DIR"/Versions/B/XPCServices/*.xpc; do
        [ -d "$xpc" ] && echo "    Signing: $(basename "$xpc")" \
            && codesign --force --sign "$DEVELOPER_ID" --options runtime "$xpc"
    done
    for app in "$SPARKLE_DIR"/Versions/B/*.app; do
        [ -d "$app" ] && echo "    Signing: $(basename "$app")" \
            && codesign --force --sign "$DEVELOPER_ID" --options runtime "$app"
    done
    codesign --force --sign "$DEVELOPER_ID" --options runtime \
        "$SPARKLE_DIR/Versions/B/Autoupdate" 2>/dev/null || true
fi

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

# The DMG has to be rebuilt from the app we just re-signed — any existing one still
# holds build.sh's ad-hoc signature. Delegating to create-dmg.sh keeps the background
# and icon layout that a hand-rolled `hdiutil create` would throw away.
echo "==> Creating DMG for notarization..."
mkdir -p "$INSTALLER_DIR"
if command -v create-dmg &>/dev/null; then
    bash "$PROJECT_DIR/scripts/create-dmg.sh"
else
    echo "    'create-dmg' not installed — falling back to the built-in layout script."
    bash "$PROJECT_DIR/scripts/create-dmg-simple.sh"
fi

if [ ! -f "$DMG_PATH" ]; then
    echo "ERROR: Expected DMG at $DMG_PATH but it was not created."
    exit 1
fi

echo "==> Signing DMG..."
codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"

echo "==> Submitting for notarization (this may take a few minutes)..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo ""
echo "==> Done! Notarized DMG: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1) ($(stat -f%z "$DMG_PATH") bytes — this is the appcast 'length')"
echo ""
echo "This DMG can be distributed outside the App Store."
echo ""
echo "Next, in this order:"
echo "  1. Upload this DMG to the GitHub release"
echo "  2. Sign the *downloaded* copy so the signature matches what Sparkle fetches:"
echo "     .build/artifacts/sparkle/Sparkle/bin/sign_update <downloaded>.dmg"
echo "  3. Add the <item> to appcast.xml, merge it, then: git push origin main:master"
echo "     (builds up to 3.4.1 read the feed from master — see README > Auto-Update)"
echo ""
