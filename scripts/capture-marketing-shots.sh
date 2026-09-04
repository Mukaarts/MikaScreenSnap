#!/usr/bin/env bash
#
# capture-marketing-shots.sh
# MikaScreenSnap
#
# Regenerates the product screenshots used on the marketing site in web/.
#
# Everything is captured against a generated demo canvas rather than the real
# desktop, so no private content can end up in a published screenshot.
#
# Requirements — both must be granted to the terminal running this script:
#   * Screen & System Audio Recording  (for screencapture)
#   * Accessibility                    (for synthetic events / menu clicks)
#
# Usage: bash scripts/capture-marketing-shots.sh
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

APP="/Applications/Mika+ScreenSnap.app"
OUT="$PROJECT_DIR/web/public/shots"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"; pkill -f "$WORK/demostage" 2>/dev/null || true' EXIT

mkdir -p "$OUT"

echo "==> Building helpers"
swiftc -O scripts/UIDriver.swift -o "$WORK/uidriver"
swiftc -O scripts/DemoStage.swift -o "$WORK/demostage"
UID_BIN="$WORK/uidriver"

echo "==> Generating the demo canvas"
swift scripts/GenerateDemoCanvas.swift

echo "==> Restarting the app so no stale overlay panels are left over"
osascript -e 'tell application id "lu.daumedia.screensnap" to quit' 2>/dev/null || true
sleep 1.5
pkill -f "Mika+ScreenSnap.app" 2>/dev/null || true
sleep 1
open "$APP"
sleep 3.5

# ---------------------------------------------------------------- menu bar --
# The menu bar item is owned by Control Center and titled with the bundle id,
# so it is located by coordinate: read its frame, then click its centre.
echo "==> Capturing the menu bar dropdown"
MENU_FRAME=$("$UID_BIN" list | awk -F'\t' '$5 ~ /lu.daumedia.screensnap/ {print $2; exit}')
if [ -n "$MENU_FRAME" ]; then
  MX=$(echo "$MENU_FRAME" | awk -F, '{print $1 + $3/2}')
  MY=$(echo "$MENU_FRAME" | awk -F, '{print $2 + $4/2}')
  "$UID_BIN" click "$MX" "$MY"
  sleep 1.5
  "$UID_BIN" shot "Mika+ScreenSnap" "$OUT/menubar.png" 200 600
  "$UID_BIN" key escape
  sleep 0.8
else
  echo "    ! menu bar item not found — skipping menubar.png"
fi

# --------------------------------------------------------------- settings --
echo "==> Capturing the settings window"
osascript >/dev/null 2>&1 <<'APPLESCRIPT' || true
tell application "System Events" to tell process "MikaScreenSnap"
  click menu bar item 1 of menu bar 2
  delay 0.8
  click menu item "Preferences..." of menu 1 of menu bar item 1 of menu bar 2
end tell
APPLESCRIPT
sleep 2.5
# A click on the window first makes it key, which renders the accent colours.
PREFS_FRAME=$("$UID_BIN" list "Mika+ScreenSnap" | awk -F'\t' '$5 ~ /Settings/ {print $2; exit}')
if [ -n "$PREFS_FRAME" ]; then
  PX=$(echo "$PREFS_FRAME" | awk -F, '{print $1 + $3/2}')
  PY=$(echo "$PREFS_FRAME" | awk -F, '{print $2 + 14}')
  "$UID_BIN" click "$PX" "$PY"
  sleep 1
  "$UID_BIN" shot "Mika+ScreenSnap" "$OUT/preferences.png" 300 800
  osascript -e 'tell application "System Events" to tell process "MikaScreenSnap" to click button 1 of window 1' >/dev/null 2>&1 || true
  sleep 1
else
  echo "    ! settings window not found — skipping preferences.png"
fi

# ----------------------------------------------------------------- editor --
# The hero shot: capture a region of the demo canvas, then drive the editor to
# blur the fake credentials, highlight a line and point an arrow at a metric.
#
# The capture region deliberately stays above y=700, clear of any floating
# assistive panels in the lower right of the display.
echo "==> Capturing the annotation editor"
"$WORK/demostage" installer/demo-canvas.png &
sleep 1.5

"$UID_BIN" key ctrl+shift+cmd+4
sleep 2.5
"$UID_BIN" drag 55 55 1865 695
sleep 3

# The stage floats above the editor, so it has to go before the editor can
# receive the drawing events.
pkill -f "$WORK/demostage" 2>/dev/null || true
sleep 1

if "$UID_BIN" id "Mika+ScreenSnap" "Annotate" >/dev/null 2>&1; then
  # The first click only makes the window key; drawing needs it focused.
  "$UID_BIN" click 592 143
  sleep 1

  "$UID_BIN" key b; sleep 0.5     # blur the credentials panel
  "$UID_BIN" drag 228 545 895 633; sleep 1.2
  "$UID_BIN" key h; sleep 0.5     # highlight a line of body text
  "$UID_BIN" drag 232 468 690 486; sleep 1.2
  "$UID_BIN" key a; sleep 0.5     # arrow pointing at the coverage figure
  "$UID_BIN" drag 1310 690 1468 617; sleep 1.5

  "$UID_BIN" shot "Mika+ScreenSnap" "$OUT/editor.png" 400 900
  osascript -e 'tell application "System Events" to tell process "MikaScreenSnap" to click button 1 of window "Annotate Screenshot"' >/dev/null 2>&1 || true
else
  echo "    ! editor window not found — skipping editor.png"
fi

# ------------------------------------------------------------------ icon ---
cp Resources/AppIcon.png "$PROJECT_DIR/web/public/appicon.png"

echo
echo "Done. Files in web/public/shots:"
ls -la "$OUT"
echo
echo "Review every image before publishing. The screenshot history browser is"
echo "deliberately not captured here: it renders real files from the user's"
echo "save folder and would leak private content."
