#!/bin/bash
# sign-local.sh — Ad-hoc code signing for local development/testing
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/Mika+ScreenSnap.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: App bundle not found at $APP_BUNDLE"
    echo "Run 'bash scripts/build.sh' first."
    exit 1
fi

echo "==> Removing quarantine attributes..."
xattr -cr "$APP_BUNDLE"

echo "==> Signing embedded frameworks (inside-out)..."
# Sign any embedded frameworks first
if [ -d "$APP_BUNDLE/Contents/Frameworks" ]; then
    for fw in "$APP_BUNDLE/Contents/Frameworks/"*.framework; do
        if [ -d "$fw" ]; then
            echo "    Signing: $(basename "$fw")"
            codesign --force --sign - --options runtime "$fw"
        fi
    done
fi

echo "==> Signing app bundle..."
codesign --force --sign - \
    --entitlements "$PROJECT_DIR/Resources/MikaScreenSnap.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

echo "==> Verifying signature..."
if codesign --verify --deep --strict "$APP_BUNDLE" 2>&1; then
    echo "    Signature valid!"
else
    echo "ERROR: Signature verification failed!"
    exit 1
fi

echo ""
echo "==> Done. App is signed for local use."
echo ""
