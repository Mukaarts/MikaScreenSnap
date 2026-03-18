# Changelog

## [3.3.1] - 2026-03-18

### Fixed
- **Check for Updates** — Sparkle auto-update now works; replaced placeholder `SUFeedURL` and `SUPublicEDKey` in Info.plist with real values
- **Update menu button** — now visually disabled when Sparkle updater is not ready

### Added
- `appcast.xml` — initial Sparkle appcast hosted on GitHub for update checks

## [3.3.0] - 2026-03-18

### Added
- **First Launch Onboarding** — 3-screen guided flow (welcome, permissions, shortcuts) for new users
- **Screen Recording permission warning** in menubar when not granted
- **"Show Onboarding Again"** button in Preferences

## [3.2.0] - 2026-03-18

### Added
- **Launch at Login** — optional auto-start at macOS login via SMAppService; toggle in Preferences > General

### Changed
- Preferences window: new "General" section with Launch at Login toggle; window height increased for new section

## [3.1.0] - 2026-03-15

### Added
- **DMG Installer** — professional DMG with custom branded background, app icon, and Applications drop link
- **Build Pipeline Scripts** — enhanced `scripts/build.sh` with `--clean` flag and Sparkle framework embedding
- **Sparkle Auto-Update** — integrated Sparkle 2.6+ for automatic update checks via menubar menu
- **Code Signing Scripts** — `scripts/sign-local.sh` for ad-hoc signing, `scripts/notarize.sh` for Apple notarization
- **DMG Background Generator** — `scripts/GenerateDMGBackground.swift` generates branded installer backgrounds
- **Simple DMG Fallback** — `scripts/create-dmg-simple.sh` creates basic DMG with only hdiutil (no dependencies)

### Changed
- `build.sh` (root) is now a thin wrapper delegating to `scripts/build.sh`
- `Scripts/` directory renamed to `scripts/` (lowercase convention)
- About window now reads version dynamically from `Bundle.main` instead of hardcoded string
- Info.plist: added `SUFeedURL` and `SUPublicEDKey` for Sparkle auto-update
- Package.swift: added Sparkle dependency

## [3.0.0] - 2026-03-15

### Added
- **OCR Text Extraction** — select a screen region (`Shift+Cmd+6`) to recognize text via Vision framework; copies to clipboard automatically; HUD result panel with Copy / Copy as Markdown; also available inside the editor via "Extract Text" button with drag-to-select
- **Color Picker** — screen-wide pixel color picker (`Shift+Cmd+7`) with 8x magnifying loupe, crosshair, and live HEX/RGB/HSL display; click copies HEX to clipboard with toast notification; Shift+click adds to palette; Color History submenu in menubar (last 10 colors)
- **Measurement Tool** — standalone fullscreen overlay (`Shift+Cmd+8`) and in-editor ruler tool (`M` key); point-to-point and rectangle measurement modes; dashed guide lines; Space toggles px/pt; measurements are non-destructive (not exported)
- **Pin Screenshot** — float any screenshot as an always-on-top panel; drag to move, scroll wheel for opacity (20-100%), Shift+drag for proportional resize; right-click menu (Copy/Save/Edit/Opacity/Close); double-click to dismiss; persistent across app restarts; Pin button in editor toolbar and bottom bar
- **Auto-Save & History** — screenshots automatically saved to ~/Pictures/MikaScreenSnap/ (configurable); History Browser (`Shift+Cmd+H`) with thumbnail grid, search by date/filename, context menu; Preferences window with auto-save toggle, folder picker, format selection (PNG/JPEG with quality slider)
- 4 new global hotkeys: `Shift+Cmd+6` (OCR), `Shift+Cmd+7` (Color Picker), `Shift+Cmd+8` (Measure), `Shift+Cmd+H` (History)
- Pinned Screenshots and Color History submenus in menubar
- Preferences window (`Cmd+,`)
- Vision framework linked for OCR support

### Changed
- AppState expanded with historyManager, preferences, colorHistory, pinnedPanels
- CaptureEngine: postCapture now auto-saves to history
- AnnotationEditor: appState property for Pin/History integration
- AnnotationToolbar: Extract Text and Pin action buttons added
- AnnotationBottomBar: Pin button added
- DrawingToolType: `.measure` case added
- AnnotationCanvasView: MeasurementTool registered, OCR selection mode with visual feedback

## [2.0.0] - 2026-03-15

### Added
- 10 annotation tools: Arrow, Rectangle, Ellipse, Line, Freehand, Text, Highlight, Blur, Pixelate + Selection tool
- Selection tool with 8 resize handles, move, and delete support
- Shift-key constraints: 45-degree snap (Arrow/Line), square (Rectangle), circle (Ellipse)
- Freehand drawing with Catmull-Rom to Bezier smoothing
- Pixelate annotation tool (CIPixellate)
- Zoom/Pan: Cmd+=/-, Cmd+0, trackpad pinch-to-zoom, Space+Drag pan
- Bottom status bar with zoom percentage, image dimensions, and action buttons
- Copy (Cmd+C), Save (Cmd+S), Save As (Shift+Cmd+S), Discard actions
- Keyboard shortcuts for all tools: V/A/R/E/L/F/T/H/B/X
- Escape: quick-capture (copy original) when no annotations, confirm dialog when unsaved
- Custom color picker via ColorPicker
- NSUndoManager-based undo/redo with proper snapshot/restore

### Changed
- Complete architecture rewrite: protocol-based Annotation system with self-drawing annotations
- Tool system: DrawingTool protocol with 11 tool implementations
- Affine transform-based coordinate system for proper zoom/pan support
- Stroke width options changed to 2/4/6px
- Renderer simplified: annotations draw themselves via draw(in:baseImage:)
- Editor window now has toolbar (top) + canvas (center) + bottom bar layout

### Removed
- PreviewWindow.swift (unused since v1.1.0)
- Old AnnotationModel.swift (replaced by AnnotationModels.swift)
- Old AnnotationEditorWindow.swift (replaced by AnnotationEditor.swift)

## [1.1.0] - 2026-03-15

### Added
- Annotation editor with arrow, rectangle, text, and blur tools
- Customizable colors (6 presets) and line widths (thin, medium, thick)
- Undo/redo support (Cmd+Z / Cmd+Shift+Z)
- Save annotated screenshots as PNG
- Copy annotated screenshots to clipboard
- NSPrincipalClass in Info.plist for proper app recognition

### Changed
- Screenshots now open in annotation editor instead of simple preview window
- Post-capture flow: capture → annotation editor → copy/save

## [1.0.0] - 2026-03-15

### Added
- Menubar app with camera viewfinder icon
- Full screen capture (Ctrl+Shift+Cmd+3)
- Area selection capture (Ctrl+Shift+Cmd+4)
- Window capture (Ctrl+Shift+Cmd+5)
- Global hotkey registration via Carbon
- Screen capture permission check on launch
- Preview window with copy/save actions
- Clipboard integration
- Hardened runtime with code signing
- Build script for app bundle assembly
