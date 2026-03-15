# CLAUDE.md — MikaScreenSnap

## Project Overview

MikaScreenSnap (Mika+ScreenSnap) is a lightweight macOS menubar screenshot tool with a professional annotation editor and power features. Built with Swift 6.0 strict concurrency, targeting macOS 14+ (Sonoma).

## Build & Run

```bash
# Build release
swift build -c release

# Build app bundle (compiles + assembles .app + code signs)
bash build.sh

# Run (must use .app bundle, not swift run)
open "build/Mika+ScreenSnap.app"
```

## Architecture

- **Pure Swift Package** — no Xcode project, uses `Package.swift`
- **Menubar app** — `NSApp.setActivationPolicy(.accessory)` by default, switches to `.regular` when editor/history windows open
- **Strict concurrency** — `@MainActor` isolation on all UI, `@Observable` for state, `nonisolated(unsafe)` for Carbon callback bridges
- **Frameworks:** ScreenCaptureKit, Carbon (hotkeys), Vision (OCR), UniformTypeIdentifiers, CoreImage (blur/pixelate), Sparkle (auto-update)
- **Build pipeline:** `scripts/build.sh` compiles, assembles .app, embeds Sparkle.framework, signs. DMG creation via `scripts/create-dmg.sh` or `scripts/create-dmg-simple.sh`. Notarization via `scripts/notarize.sh`

## Key Patterns

- **NSPanel pattern** — used for AreaSelection, PinnedScreenshot, OCRResult, ColorLoupe, Toast, MeasurementOverlay. Always borderless+nonactivating for overlays, .floating/.screenSaver level
- **DrawingTool protocol** — tools implement mouseDown/Dragged/Up + drawPreview. Canvas dispatches events to active tool. Tools work in image pixel space
- **Annotation protocol** — self-drawing annotations with snapshot/restore for undo. Sorted by zIndex for render order
- **Carbon hotkeys** — EventHotKeyID with static instance pointer for callback. Signature: `0x4D534E53`
- **SwiftUI in AppKit** — Toolbar and BottomBar are `NSHostingView` with `@Observable` store binding

## File Organization

All source files in `Sources/`, tools in `Sources/Tools/`. No subdirectories beyond that. Resources (Info.plist, entitlements) in `Resources/`. Build/distribution scripts in `scripts/`. Generated installer assets (DMGs, backgrounds) in `installer/` (gitignored except `.gitkeep`).

## Conventions

- All new UI classes must be `@MainActor`
- New NSPanel-based features follow the AreaSelectionPanel pattern (borderless, nonactivating, clear background)
- New drawing tools implement `DrawingTool` protocol and register in `AnnotationCanvasView.setupTools()`
- New DrawingToolType cases need systemImage, label, and keyboard shortcut in AnnotationEditor
- Window controllers manage activation policy: `.regular` on show, `.accessory` on close (only if no other windows visible)
- Pinned panels don't count for activation policy decisions
- Scripts use lowercase `scripts/` directory (not `Scripts/`)
- Build scripts reference `PROJECT_DIR` relative to script location: `$(cd "$(dirname "$0")/.." && pwd)`
- Sparkle: `@preconcurrency import Sparkle` for Swift 6.0 concurrency compatibility
