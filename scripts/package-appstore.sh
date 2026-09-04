#!/bin/bash
set -euo pipefail

# Signs and packages the Mac App Store edition for submission.
#
# Separate from build-appstore.sh on purpose: that one produces an ad-hoc signed bundle for
# local testing and needs no account. This one needs a Developer Program membership and two
# certificates, and its output goes to Apple.
#
# What it does:
#   1. Rebuilds the bundle through build-appstore.sh (so its self-check runs)
#   2. Re-signs it with Apple Distribution — replacing the ad-hoc signature
#   3. Wraps it in a .pkg signed with 3rd Party Mac Developer Installer
#   4. Validates the package against App Store Connect before anything is uploaded
#
# Uploading is a separate, deliberate step — see the end of this script.

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build-appstore"
APP_NAME="Mika+ScreenSnap"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
ENTITLEMENTS="$PROJECT_DIR/Resources/MikaScreenSnap-AppStore.entitlements"

# Optional local overrides; never committed. See appstore-credentials.example.sh.
# shellcheck source=/dev/null
[ -f "$PROJECT_DIR/scripts/appstore-credentials.sh" ] && source "$PROJECT_DIR/scripts/appstore-credentials.sh"

TEAM_ID="${MIKA_TEAM_ID:-CWJM4J4HFN}"

# `|| true` is not decoration: under `set -e` a grep with no match ends the script, and it
# would end it *before* the error message explaining what is missing. That exact mistake
# once made build-appstore.sh report one passing check and then vanish.
find_identity() {  # $1 = certificate prefix, $2 = -p codesigning or empty
    security find-identity -v ${2:-} 2>/dev/null \
        | grep "$1" 2>/dev/null | grep "$TEAM_ID" 2>/dev/null | head -1 \
        | sed -E 's/.*"(.*)"/\1/' || true
}

APP_IDENTITY="${MIKA_APP_IDENTITY:-$(find_identity 'Apple Distribution' '-p codesigning')}"
# Installer certificates are not code-signing identities, so they are looked up without
# the -p filter.
INSTALLER_IDENTITY="${MIKA_INSTALLER_IDENTITY:-$(find_identity '3rd Party Mac Developer Installer')}"

missing=0
if [ -z "$APP_IDENTITY" ]; then
    echo "ERROR: No 'Apple Distribution' certificate for team $TEAM_ID in the keychain."
    missing=1
fi
if [ -z "$INSTALLER_IDENTITY" ]; then
    echo "ERROR: No '3rd Party Mac Developer Installer' certificate for team $TEAM_ID."
    missing=1
fi
if [ "$missing" -ne 0 ]; then
    echo ""
    echo "Both are created once in Xcode > Settings > Accounts > Manage Certificates > +,"
    echo "or imported from a .p12 exported on another machine. 'Apple Development'"
    echo "certificates are not enough — those cannot sign for the App Store."
    echo ""
    echo "Present right now:"
    security find-identity -v 2>/dev/null | sed 's/^/  /'
    exit 1
fi

echo "==> Building the App Store bundle (runs its own self-check)..."
bash "$PROJECT_DIR/scripts/build-appstore.sh"

echo ""
echo "==> Re-signing with Apple Distribution..."
echo "    $APP_IDENTITY"
# Replaces build-appstore.sh's ad-hoc signature. The entitlements are re-applied here
# because a signature without them would sandbox nothing.
codesign --force --sign "$APP_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    --timestamp \
    "$APP_BUNDLE"

echo "==> Verifying..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

SIGNED_TEAM=$(codesign -dvv "$APP_BUNDLE" 2>&1 | sed -n 's/^TeamIdentifier=//p')
if [ "$SIGNED_TEAM" != "$TEAM_ID" ]; then
    echo "ERROR: bundle carries team '$SIGNED_TEAM', expected '$TEAM_ID'."
    exit 1
fi
echo "    Team: $SIGNED_TEAM"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")
PKG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.pkg"

echo ""
echo "==> Building installer package..."
rm -f "$PKG_PATH"
productbuild --component "$APP_BUNDLE" /Applications \
    --sign "$INSTALLER_IDENTITY" \
    "$PKG_PATH"

echo ""
echo "==> Package: $PKG_PATH ($(stat -f%z "$PKG_PATH") bytes, v$VERSION)"

# Validation catches what a local build cannot: rejected entitlements, a bundle identifier
# that is not registered, a missing provisioning profile. Cheaper than a rejected upload.
if [ -n "${MIKA_ASC_KEY_ID:-}" ] && [ -n "${MIKA_ASC_ISSUER_ID:-}" ]; then
    echo ""
    echo "==> Validating against App Store Connect (nothing is uploaded yet)..."
    xcrun altool --validate-app -f "$PKG_PATH" -t macos \
        --apiKey "$MIKA_ASC_KEY_ID" --apiIssuer "$MIKA_ASC_ISSUER_ID"
    echo ""
    echo "Validation passed. To upload:"
    echo "  xcrun altool --upload-app -f \"$PKG_PATH\" -t macos \\"
    echo "      --apiKey \"\$MIKA_ASC_KEY_ID\" --apiIssuer \"\$MIKA_ASC_ISSUER_ID\""
else
    echo ""
    echo "Set MIKA_ASC_KEY_ID and MIKA_ASC_ISSUER_ID to validate and upload."
    echo "See scripts/appstore-credentials.example.sh."
fi
