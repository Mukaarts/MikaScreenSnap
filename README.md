# Mika+ScreenSnap v3.3.1

A lightweight macOS menubar screenshot tool with a professional annotation editor and power features. Capture your screen, annotate it with 11 tools, extract text via OCR, pick colors, measure pixels, pin screenshots, and manage your history — all without leaving your workflow.

## Features

- **First Launch Onboarding** — guided setup for permissions, shortcuts, and launch-at-login
- **Launch at Login** — optional auto-start at macOS login (Preferences > General)
- **Menubar App** — lives in your menubar, no Dock icon
- **Capture Modes**
  - Full Screen (`Ctrl+Shift+Cmd+3`)
  - Area Selection (`Ctrl+Shift+Cmd+4`)
  - Window (`Ctrl+Shift+Cmd+5`)
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
  - Shift+Click adds to palette
  - Color History submenu (last 10 colors)
- **Measurement Tool**
  - `Shift+Cmd+8` — fullscreen overlay with point-to-point and rectangle modes
  - Guide lines, px/pt toggle (Space), coordinates display
  - Also available as editor tool (`M` key) — non-destructive, not exported
- **Pin Screenshot**
  - Float any screenshot as always-on-top panel
  - Drag to move, scroll wheel for opacity, Shift+drag to resize
  - Right-click menu: Copy, Save, Edit, Opacity, Close
  - Persistent across app restarts (max 20)
- **Auto-Save & History**
  - Screenshots auto-saved to ~/Pictures/MikaScreenSnap/
  - History Browser (`Shift+Cmd+H`) with thumbnail grid and search
  - Configurable: folder, format (PNG/JPEG), quality
- **Zoom & Pan**
  - `Cmd+=` / `Cmd+-` / `Cmd+0` (fit)
  - Trackpad pinch-to-zoom
  - `Space+Drag` to pan
- **Export**
  - Copy to clipboard (`Cmd+C`)
  - Save to Desktop (`Cmd+S`)
  - Save As (`Shift+Cmd+S`)
  - Pin to screen
  - Escape: quick-capture (no annotations) or confirm dialog (with annotations)

## Keyboard Shortcuts

### Global Hotkeys

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+Cmd+3` | Capture Full Screen |
| `Ctrl+Shift+Cmd+4` | Capture Area |
| `Ctrl+Shift+Cmd+5` | Capture Window |
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
| `Cmd+S` | Save to Desktop & close |
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

```bash
export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="your@email.com"
export TEAM_ID="YOURTEAMID"
export NOTARIZE_PASSWORD="xxxx-xxxx-xxxx-xxxx"
bash scripts/notarize.sh
```

### DMG Background

Regenerate the branded DMG background images:

```bash
swift scripts/GenerateDMGBackground.swift
```

### Auto-Update (Sparkle)

The app uses Sparkle 2.x for auto-updates. Configuration:
- **Feed URL:** `https://raw.githubusercontent.com/Mukaarts/MikaScreenSnap/main/appcast.xml`
- **Ed25519 public key:** configured in `Resources/Info.plist` (`SUPublicEDKey`)
- **Private key:** stored in the macOS Keychain (generated via `.build/artifacts/sparkle/Sparkle/bin/generate_keys`)

To publish a new update:
1. Build the release `.app` bundle
2. Sign the update: `.build/artifacts/sparkle/Sparkle/bin/sign_update path/to/archive.zip`
3. Update `appcast.xml` with the new version, download URL, and signature
4. Or use `generate_appcast` to auto-generate from a folder of releases

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
