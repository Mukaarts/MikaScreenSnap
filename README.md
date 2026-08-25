# Mika+ScreenSnap v3.5.0

A lightweight macOS menubar screenshot tool with a professional annotation editor and power features. Capture your screen, annotate it with 11 tools, extract text via OCR, pick colors, measure pixels, pin screenshots, and manage your history — all without leaving your workflow.

## Features

- **First Launch Onboarding** — guided setup for permissions, shortcuts, and launch-at-login
- **Launch at Login** — optional auto-start at macOS login (Preferences > General)
- **Preferences** — four-tab window in the native System Settings layout (General, Shortcuts, Annotation, Advanced) with customizable hotkeys, annotation defaults, app exclusions, storage management, and reset
- **Menubar App** — lives in your menubar, no Dock icon
- **Exclude apps from capture** — named apps never appear in any screenshot, OCR or colour sample; pick them from the running list or straight from disk
- **Capture Modes**
  - Full Screen (`Ctrl+Shift+Cmd+3`)
  - Area Selection (`Ctrl+Shift+Cmd+4`)
  - Window — pick one by pointing at it, or grab the frontmost with `Ctrl+Shift+Cmd+5`
- **Annotation Editor** — opens automatically after each capture
  - **Drawing Tools:** Arrow, Rectangle, Ellipse, Line, Freehand
  - **Text Tool:** Click to place editable text with background pill
  - **Effect Tools:** Highlight (yellow overlay), Blur (Gaussian), Pixelate
  - **Measurement Tool:** Non-destructive ruler for pixel measurements (not exported)
  - **Selection Tool:** Click to select, drag to move, 8 resize handles, Delete to remove
  - **Shift Constraints:** 45-degree snap (Arrow/Line), square (Rectangle), circle (Ellipse)
  - **Freehand:** Smooth Catmull-Rom curves
  - 6 color presets + custom color picker
  - 3 stroke widths (2/4/6px)
  - Undo / Redo (`Cmd+Z` / `Cmd+Shift+Z`)
- **OCR Text Extraction**
  - `Shift+Cmd+6` — select area, text is recognized and copied to clipboard
  - In-editor: "Extract Text" button → drag region → popover with result
  - Supports German, English, French
- **Color Picker**
  - `Shift+Cmd+7` — magnifying loupe follows cursor with 8x zoom
  - Click copies HEX to clipboard with toast notification
  - Shift+Click adds to the palette
  - Color History and Colour Palette submenus in the menubar, both clearable
- **Measurement Tool**
  - `Shift+Cmd+8` — fullscreen overlay with point-to-point and rectangle modes
  - Guide lines, px/pt toggle (Space in the overlay, `U` in the editor), coordinates display
  - Also available as editor tool (`M` key) — non-destructive, not exported
- **Pin Screenshot**
  - Float any screenshot as always-on-top panel
  - Drag to move, scroll wheel for opacity, Shift+drag to resize
  - Right-click menu: Copy, Save, Edit, Opacity, Close
  - Persistent across app restarts (max 20)
- **Auto-Save & History**
  - Screenshots auto-saved to ~/Pictures/MikaScreenSnap/ — the saved file is replaced with the edited image when you export, so a redacted capture never leaves the original behind
  - History Browser (`Shift+Cmd+H`) with thumbnail grid and search
  - Configurable: folder, format (PNG/JPEG), quality
- **Zoom & Pan**
  - `Cmd+=` / `Cmd+-` / `Cmd+0` (fit)
  - Trackpad pinch-to-zoom
  - `Space+Drag` to pan
- **Export**
  - Copy to clipboard (`Cmd+C`)
  - Save to the configured folder and format (`Cmd+S`) — updates the auto-saved file rather than adding a second one
  - Save As (`Shift+Cmd+S`)
  - Pin to screen
  - Escape: quick-capture (no annotations) or confirm dialog (with annotations)

## Keyboard Shortcuts

### Global Hotkeys

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+Cmd+3` | Capture Full Screen |
| `Ctrl+Shift+Cmd+4` | Capture Area |
| `Ctrl+Shift+Cmd+5` | Capture Frontmost Window |
| `Shift+Cmd+6` | Capture Text (OCR) |
| `Shift+Cmd+7` | Color Picker |
| `Shift+Cmd+8` | Measure |
| `Shift+Cmd+H` | Screenshot History |

### Editor Shortcuts

| Key | Action |
|-----|--------|
| `V` | Selection tool |
| `A` | Arrow tool |
| `R` | Rectangle tool |
| `E` | Ellipse tool |
| `L` | Line tool |
| `F` | Freehand tool |
| `T` | Text tool |
| `H` | Highlight tool |
| `B` | Blur tool |
| `X` | Pixelate tool |
| `M` | Measurement tool |
| `Cmd+Z` | Undo |
| `Shift+Cmd+Z` | Redo |
| `Cmd+C` | Copy & close |
| `Cmd+S` | Save to the configured folder & close |
| `Shift+Cmd+S` | Save As... |
| `Cmd+=` / `Cmd+-` | Zoom in/out |
| `Cmd+0` | Zoom to fit |
| `Space+Drag` | Pan |
| `Delete` | Delete selected annotation |
| `Escape` | Close editor |

## Requirements

- macOS 14.0 (Sonoma) or later
- Screen capture permission

## Build

```bash
./build.sh
```

This compiles the project, assembles the `.app` bundle, embeds Sparkle.framework, and signs with hardened runtime.

Use `./build.sh --clean` to clean the `.build/` directory before compiling.

## Test

```bash
swift test
```

Covers the arithmetic that has no UI to catch it: multi-display capture coordinates,
hotkey encoding, colour conversion, redaction strength and filename collisions.

## Install

```bash
cp -r "build/Mika+ScreenSnap.app" /Applications/
```

## Run

```bash
open "build/Mika+ScreenSnap.app"
```

> **Note:** Always run via the `.app` bundle, not `swift run`, to ensure proper bundle identifier and window activation.

## Distribution

### Create DMG Installer

**Professional DMG** (with custom background and layout):

```bash
brew install create-dmg  # one-time prerequisite
bash scripts/create-dmg.sh
```

**Simple DMG** (no dependencies, uses only hdiutil):

```bash
bash scripts/create-dmg-simple.sh
```

Both output to `installer/Mika+ScreenSnap-v{VERSION}.dmg`.

### Code Signing & Notarization

**Local ad-hoc signing** (for development/testing):

```bash
bash scripts/sign-local.sh
```

**Developer ID signing + Apple notarization** (for distribution):

Store the credentials in the keychain once — the app-specific password (from
[appleid.apple.com](https://appleid.apple.com)) is prompted for, so it never lands in
your shell history:

```bash
xcrun notarytool store-credentials "MikaScreenSnap" \
    --apple-id "your@email.com" --team-id "YOURTEAMID"
```

After that, no environment is needed:

```bash
bash scripts/notarize.sh
```

The script re-signs the bundle with your Developer ID (including Sparkle's nested XPC
services), rebuilds the DMG through `create-dmg.sh` so the layout survives, notarizes,
staples, and prints the byte size and `sign_update` command the appcast entry needs.
The certificate is picked up from the keychain automatically; override `DEVELOPER_ID`
or `NOTARY_PROFILE` if you have several.

### DMG Background

Regenerate the branded DMG background images:

```bash
swift scripts/GenerateDMGBackground.swift
```

### Auto-Update (Sparkle)

The app uses Sparkle 2.x for auto-updates. Configuration:
- **Feed URL:** `https://raw.githubusercontent.com/daumedia/MikaScreenSnap/main/appcast.xml` (as configured in `Resources/Info.plist`)
- **Ed25519 public key:** configured in `Resources/Info.plist` (`SUPublicEDKey`)
- **Private key:** stored in the macOS Keychain (generated via `.build/artifacts/sparkle/Sparkle/bin/generate_keys`)

> **Keep `master` in sync.** Up to and including 3.4.1 the feed URL pointed at the
> `master` branch, and those builds have it compiled in. Until every install has moved
> to a later version, `master` has to be pushed alongside `main` (`git push origin
> main:master`) or those users silently stop receiving updates. This is what made the
> 3.4.1 entry invisible at first — `master` had not been touched since March.

Publishing a new version, in this order — the appcast comes **last**, because merging it
is what offers the update to every existing install:

1. Bump the version in `Resources/Info.plist`, `README.md` and `web/lib/content.ts`, and
   add a `CHANGELOG.md` entry
2. `bash build.sh`
3. `bash scripts/notarize.sh` — signs, rebuilds the DMG, notarizes and staples it.
   Do not skip this: an un-notarized build is blocked by Gatekeeper on first launch
4. Create the GitHub release and upload the notarized DMG. Verify the download URL
   resolves — `web/lib/content.ts` derives it from the version string
5. `.build/artifacts/sparkle/Sparkle/bin/sign_update installer/Mika+ScreenSnap-vX.Y.Z.dmg`
   over the DMG **as downloaded from GitHub**, so the signature matches what Sparkle
   will actually fetch
6. Add the `<item>` to `appcast.xml` with that signature and length, merge it, and push
   `main:master`

## Project Structure

```
Sources/
├── MikaScreenSnapApp.swift       # App entry point, AppState & menubar
├── CaptureEngine.swift           # Screenshot capture + OCR/ColorPicker/Measure launchers
├── HotkeyManager.swift           # 7 global hotkeys (Carbon)
├── AreaSelectionOverlay.swift     # Area selection UI
├── ClipboardManager.swift        # Clipboard & file save
├── AppPreferences.swift          # UserDefaults-backed preferences
├── ScreenshotHistoryManager.swift # Auto-save, thumbnails, history
├── HistoryBrowserWindow.swift    # History browser window (LazyVGrid)
├── PreferencesView.swift         # Preferences window
├── OCREngine.swift               # Vision framework text recognition
├── OCRResultPanel.swift          # HUD result panel for OCR
├── ColorPickerEngine.swift       # Pixel sampling & color conversion
├── ColorLoupePanel.swift         # Magnifying loupe controller
├── ColorPickerToast.swift        # Toast notification for picked colors
├── ColorHistoryManager.swift     # Recent colors & palette persistence
├── MeasurementOverlay.swift      # Fullscreen measurement overlay
├── PinnedScreenshotPanel.swift   # Floating pinned screenshot panel
├── PinnedScreenshotManager.swift # Pin persistence & lifecycle
├── AnnotationModels.swift        # Annotation protocol, 9 types, AnnotationStore
├── DrawingToolProtocol.swift     # DrawingTool protocol
├── AnnotationCanvasView.swift    # Drawing canvas with zoom/pan (NSView)
├── AnnotationRenderer.swift      # Full-resolution export renderer
├── AnnotationToolbar.swift       # Toolbar UI (SwiftUI)
├── AnnotationBottomBar.swift     # Bottom status bar (SwiftUI)
├── AnnotationEditor.swift        # Editor window controller
└── Tools/
    ├── ArrowTool.swift
    ├── RectangleTool.swift
    ├── EllipseTool.swift
    ├── LineTool.swift
    ├── FreehandTool.swift
    ├── TextTool.swift
    ├── HighlightTool.swift
    ├── BlurTool.swift
    ├── PixelateTool.swift
    ├── SelectionTool.swift
    └── MeasurementTool.swift
```

## License

[MIT](LICENSE)
