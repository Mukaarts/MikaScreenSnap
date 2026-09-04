#!/bin/bash
set -euo pipefail

# Builds the Mac App Store edition of Mika+ScreenSnap.
#
# Deliberately a separate script rather than a flag on build.sh: that one signs ad-hoc and
# embeds Sparkle.framework, and both are wrong here. Two short scripts read better than one
# with two modes.
#
# What differs from the direct-download build:
#   - App Sandbox on, via Resources/MikaScreenSnap-AppStore.entitlements
#   - no Sparkle: not resolved as a dependency, not linked, not embedded
#   - no SUFeedURL / SUPublicEDKey in Info.plist
#
# Signing and packaging for submission is package-appstore.sh, not this script.

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build-appstore"
APP_NAME="Mika+ScreenSnap"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

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

echo "==> Building MikaScreenSnap (App Store edition)..."
cd "$PROJECT_DIR"
export MIKA_APPSTORE=1
swift build -c release 2>&1

EXECUTABLE=$(swift build -c release --show-bin-path)/MikaScreenSnap

echo "==> Assembling app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/MikaScreenSnap"

# Info.plist is DERIVED from the shared one, not maintained as a second file. That way the
# two editions cannot drift apart in version number — there is only one place to bump.
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
for key in SUFeedURL SUPublicEDKey; do
    /usr/libexec/PlistBuddy -c "Delete :$key" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
done

if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
for img in MenubarIconTemplate.png MenubarIconTemplate@2x.png; do
    if [ -f "$PROJECT_DIR/Resources/$img" ]; then
        cp "$PROJECT_DIR/Resources/$img" "$APP_BUNDLE/Contents/Resources/$img"
    fi
done

# No Sparkle.framework here — with MIKA_APPSTORE=1 the dependency is never resolved, so
# there is nothing to embed and nothing to link against.

echo "==> Signing (ad-hoc, for local testing only)..."
codesign --force --sign - \
    --entitlements "$PROJECT_DIR/Resources/MikaScreenSnap-AppStore.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")

echo ""
echo "==> Self-check"

# Collected once: `codesign -d` is slow, and re-running it per check made the first
# failing grep abort the whole script under `set -e`.
ENTITLEMENTS=$(codesign -d --entitlements - "$APP_BUNDLE" 2>/dev/null || true)
LINKED=$(otool -L "$APP_BUNDLE/Contents/MacOS/MikaScreenSnap" 2>/dev/null || true)
PLIST_KEYS=$(/usr/libexec/PlistBuddy -c "Print" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true)

FAIL=0
report() {  # $1 = description, $2 = ok|fail
    if [ "$2" = "ok" ]; then echo "    ok   $1"; else echo "    FAIL $1"; FAIL=1; fi
}
must_contain()  { case "$2" in *"$1"*) echo ok ;; *) echo fail ;; esac; }
must_not_have() { case "$2" in *"$1"*) echo fail ;; *) echo ok ;; esac; }

report "sandbox enabled" \
    "$(must_contain 'com.apple.security.app-sandbox' "$ENTITLEMENTS")"
report "user-selected file access present" \
    "$(must_contain 'com.apple.security.files.user-selected.read-write' "$ENTITLEMENTS")"
report "app-scope bookmarks present" \
    "$(must_contain 'com.apple.security.files.bookmarks.app-scope' "$ENTITLEMENTS")"
report "no temporary-exception entitlements" \
    "$(must_not_have 'temporary-exception' "$ENTITLEMENTS")"
report "no undocumented screen-capture entitlement" \
    "$(must_not_have 'com.apple.security.screen-capture' "$ENTITLEMENTS")"
report "no library-validation opt-out" \
    "$(must_not_have 'disable-library-validation' "$ENTITLEMENTS")"
report "no SUFeedURL in Info.plist" \
    "$(must_not_have 'SUFeedURL' "$PLIST_KEYS")"
report "no SUPublicEDKey in Info.plist" \
    "$(must_not_have 'SUPublicEDKey' "$PLIST_KEYS")"
report "binary does not link Sparkle" \
    "$(must_not_have 'Sparkle' "$LINKED")"
if [ -d "$APP_BUNDLE/Contents/Frameworks/Sparkle.framework" ]; then
    report "no Sparkle.framework embedded" fail
else
    report "no Sparkle.framework embedded" ok
fi

echo ""
if [ "$FAIL" -ne 0 ]; then
    echo "==> Self-check FAILED — do not submit this bundle."
    exit 1
fi
echo "==> Build complete: $APP_BUNDLE (v$VERSION)"
echo ""
echo "This bundle is ad-hoc signed and runs locally only."
echo "For submission run: bash scripts/package-appstore.sh"
