# Changelog

## [3.6.0] - 2026-09-04 — Mac App Store edition

Mika+ScreenSnap is now built in two editions from the same source: the direct download you
already have, and a sandboxed one distributed through the Mac App Store.

**Both change with this release**, and not in the same way. The direct download keeps
everything except the Screen Recording permission, which has to be granted again. The App
Store edition starts fresh. The two sections at the bottom say exactly what happens in each
case — they are not interchangeable.

### Added

- **Mac App Store edition, sandboxed.** Screen capture, global hotkeys, the annotation
  editor, OCR, the colour picker and pinning all work the same — none of them needed the
  app to run outside the sandbox
- **You choose the screenshot folder once**, during first-run setup. The sandbox has no
  path to `~/Pictures` the app can take on its own, and writing into a hidden container
  folder would leave your screenshots somewhere you would never find them. The permission
  survives restarts, so you are asked exactly once. You can change the folder later in
  Settings

### Changed — App Store edition only

- **Updates come from the App Store**, not from the app. The bundled updater is gone
  entirely: the App Store edition contains no updater, checks no feed, and makes no
  network connection of its own. Settings shows a note where the update controls used to be
- **Apple collects its own crash reports and usage figures** for apps installed from the
  App Store, if you have allowed that under System Settings › Privacy & Security ›
  Analytics & Improvements. The app still collects nothing itself, and the developer never
  sees anything that identifies you. The direct download has no equivalent — see the
  privacy page for the full wording

### Updating the direct download

The app moves to a new bundle identifier with this release — `lu.daumedia.screensnap`. That
matters because macOS uses the identifier to find both an app's settings and its Screen
Recording permission.

- **You will be asked for Screen Recording permission again.** The permission is tied to the
  old identifier and does not transfer. Without it the app cannot capture anything, so
  first-run setup runs once more and walks you through granting it. This is the one thing
  that unavoidably resets
- **Your settings do come with you.** On first launch under the new identifier the app reads
  the old ones once and carries over hotkeys, the exclusion list, drawing defaults and your
  save location. You should not have to set anything up again
- **So do your pinned screenshots.** They live in
  `~/Library/Application Support/MikaScreenSnap/`, which is not tied to the identifier —
  they reappear as they were

### Moving to the App Store edition

Different situation, different answer: the sandbox is what changes here, not the identifier.

- **Nothing carries over.** A sandboxed app cannot read another app's settings, and it
  cannot see the folder holding your pinned screenshots — not even to check whether any
  exist. So it does not ask, and starts with defaults
- **This is expected, not a failure.** Everything you had is untouched where it was: your
  captures in their folder, your pinned images in
  `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/`. Pin them again from
  there if you want them back
- Both editions carry the same version number and the same bundle identifier, so installing
  one replaces the other rather than running alongside it

## [3.5.0] - 2026-08-25

Everything here came out of the SDD reconstruction (#31, #32), which read the shipped code
feature by feature and recorded what it actually did. Behaviour changes are listed as such.

### Fixed — data that should not have survived

- **Redacting no longer leaves the original on disk** — auto-save runs before the editor
  opens, so the saved file was always the unedited capture. Blurring a password and
  exporting left the readable original in `~/Pictures/MikaScreenSnap/`. Every export now
  replaces that file, and a capture carrying a blur or pixelate region is replaced even if
  the editor is closed without exporting
- **Pinned screenshots are deleted when closed** — closing a pin only hid the window. The
  PNG stayed in `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/` forever,
  the twenty-pin limit applied only to open windows, and `restorePins` sorted filenames
  ascending — so it restored the *oldest* twenty and a deliberately closed pin could come
  back. Restoration is now newest-first, surplus files are removed, and Preferences shows
  and can clear this storage
- **Two captures in the same second no longer overwrite each other** — filenames carried
  only second precision and were written without checking for an existing file
- **Blur no longer weakens at the edges** — the filter ran on the cropped region without
  clamping, so it mixed the border with transparent space outside it and left text sitting
  on that border far less blurred than the middle
- **Redaction strength scales with the region** — a fixed 15px radius and 10px block hid
  progressively less the larger the capture

### Fixed — failures that reached nobody

- **A failed save is reported** — six `print()` calls survived in error paths (OCR,
  launch-at-login, save, auto-save, pin limit). In an `LSUIElement` bundle they reach
  nobody, so a screenshot that failed to save vanished without a word
- **One keypress fires one capture again** — `registerHotkeys()` installed a Carbon event
  handler on every call, from `init` and from every re-binding, and nothing ever removed
  one. After *n* re-binds a single shortcut fired *n+1* captures; "Reset All Preferences"
  took the same path without the user touching a shortcut
- **Empty OCR results say so** — recognising nothing produced silence, indistinguishable
  from the feature not firing
- **Launch at Login reports failures**, and its switch now shows the system's state rather
  than the one that was asked for

### Fixed — multi-display

- **Full screen captures the display the pointer is on**, not whichever one
  ScreenCaptureKit listed first
- **Area captures compute against the display they were drawn on** — the crop was measured
  against the first display, so a selection on a second screen produced the wrong region
- **Scale comes from the capture filter** — full screen multiplied by a hard-coded 2, and
  area capture used `NSScreen.main`, which follows the key window rather than the pointer

### Changed

- **⌘S saves to the configured folder in the configured format.** It used to write a PNG
  to the Desktop regardless of both settings, and overwrote the clipboard as a side effect.
  If auto-save already wrote the capture, ⌘S updates that file instead of creating a second
  one. ⇧⌘S still asks where to put it
- **The measurement tool toggles px/pt with `U`, not space** — inside the editor space is
  the pan modifier and both fired at once
- **Onboarding asks the system for the permission** via `CGRequestScreenCaptureAccess`
  instead of only ever checking it. The app was never registered with the system, so the
  Screen Recording list a user was sent to could not contain it yet
- **Capture menu entries are disabled without the permission** rather than failing when used
- **Launch at Login is no longer pre-ticked** in onboarding; it reflects the current state
- **Recognised text is marked as concealed** on the pasteboard, so clipboard managers leave
  it alone
- Default stroke width is 4 — it was 3, which Preferences did not offer

### Added

- **Colour palette in the menubar** — shift-clicking the picker filled a palette that no
  view ever displayed. Both palette and history can now be cleared
- **Exclude apps that are not running** — "Add App…" picks a bundle from disk, so a
  password manager can be excluded before it is opened
- **Pinned-screenshot storage in Preferences** — size and a way to clear it
- **"Show toolbar labels" works** — it was offered in Preferences and read by nothing
- **Updates ask before discarding unsaved annotations** — Sparkle now has a delegate that
  can postpone the relaunch
- **A test suite** (`swift test`) — 28 tests over the arithmetic that had no coverage:
  multi-display coordinates, hotkey encoding, colour conversion, redaction strength and
  filename collisions

### Removed

- **"Floating preview" and its dismiss duration** — stored, loaded, reset and offered in
  Preferences, but read by nothing. A preview window was never built; it belongs in a
  feature of its own rather than as a switch that does nothing
- `permissionSkipped` — written by onboarding and read by nobody

## [3.4.1] - 2026-08-09

### Fixed
- **Window capture produced an empty image** — the window search sorted ascending by `windowLayer` and took the first result, but a higher `CGWindowLevel` means further front, so it picked the backmost window. Combined with `SCShareableContent.current` including the desktop layer, this selected WindowServer's backstop window, which captures as a fully transparent image. Window selection now uses `excludingDesktopWindows(_:onScreenWindowsOnly:)`, keeps only layers `0..<20`, and preserves the front-to-back order ScreenCaptureKit already provides
- **Wrong resolution on secondary displays** — window captures sized themselves from `NSScreen.main.backingScaleFactor`; they now use `SCContentFilter.contentRect` and `.pointPixelScale`, so a window is captured at the scale of the display it is actually on
- **Untitled windows were not capturable** — the candidate filter required a non-empty window title, which excluded legitimate windows from Electron, games and some Java apps
- **Color picker and loupe** — replaced the deprecated `CGWindowListCreateImage` with ScreenCaptureKit. The screen is snapshotted once per display when the picker starts, so sampling stays synchronous while the loupe redraws on every mouse move
- **Color picker on multi-display setups** — cursor coordinates were flipped against `NSScreen.main`, which follows the key window; they now use the display that owns the AppKit origin
- **Capture failures were invisible** — every error path ended in `print()`, which goes nowhere in an `LSUIElement` bundle launched from Finder
- **Accessibility pointer overlay slipped through** — the detection required an owning application with an empty bundle id, but WindowServer may report no owning application at all

### Added
- **Interactive window picker** — "Capture Window…" in the menubar opens an overlay that outlines the window under the pointer with its app icon, name and pixel size; click captures it, ESC or right-click cancels. Works across displays and on windows straddling two screens
- **Capture Frontmost Window** — the previous one-shot behaviour, still on ⌃⇧⌘5 and now also a menubar entry
- **Status toasts** — capture failures surface to the user, with a plain-language message when the screen recording permission is missing
- **Unified logging** — failures are logged under the `com.mika.mikaplusscreensnap` subsystem and readable in Console.app

## [3.4.0] - 2026-03-18

### Added
- **Preferences UI redesign** — dark-themed, four-tab preferences window (General, Shortcuts, Annotation, Advanced) matching the Mika+ brand aesthetic
- **Shortcut configuration** — inline hotkey recorder with conflict detection and restore-defaults
- **Annotation defaults** — configurable default tool, stroke color, and stroke width; "remember last tool" option
- **Capture sound toggle** — enable/disable the capture sound effect
- **Floating preview option** — configurable auto-dismiss duration (3s, 5s, 10s, never)
- **Storage management** — view screenshot count/size, clear history with confirmation
- **Reset all preferences** — one-click reset with confirmation dialog
- **Destructive color** — added `Color.MikaPlus.destructive` (#E24B4A) to brand palette

### Changed
- Preferences window size increased from 450×350 to 560×480 with transparent titlebar
- HotkeyManager refactored to support dynamic re-registration and saved bindings
- AppPreferences extended with ~10 new UserDefaults-backed properties
- AnnotationEditor now applies default tool/color/stroke from preferences
- CaptureEngine capture sound respects preferences toggle

### Fixed
- **App inaccessible after Dock close** — removed activation policy switching; app stays permanently in `.accessory` mode (fixes #18)

### Removed
- Old `Sources/PreferencesView.swift` replaced by `Sources/Preferences/` module

## [3.3.2] - 2026-03-18

### Fixed
- **Appcast parsing error** — corrected XML namespace (`sparkle` → `http://www.andymatuschak.org/xml-namespaces/sparkle`) and XML declaration encoding in `appcast.xml`; fixes "An error occurred while parsing the update feed"

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
