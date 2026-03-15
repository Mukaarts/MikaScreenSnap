# Mika+ScreenSnap

A lightweight macOS menubar screenshot tool with a built-in annotation editor. Capture your screen, annotate it, and copy or save the result — all without leaving your workflow.

## Features

- **Menubar App** — lives in your menubar, no Dock icon
- **Capture Modes**
  - Full Screen (`Ctrl+Shift+Cmd+3`)
  - Area Selection (`Ctrl+Shift+Cmd+4`)
  - Window (`Ctrl+Shift+Cmd+5`)
- **Annotation Editor** — opens automatically after each capture
  - Arrow tool
  - Rectangle tool
  - Text tool
  - Blur tool
  - 6 color presets, 3 line widths
  - Undo / Redo (`Cmd+Z` / `Cmd+Shift+Z`)
- **Export** — copy to clipboard or save as PNG

## Requirements

- macOS 14.0 (Sonoma) or later
- Screen capture permission

## Build

```bash
./build.sh
```

This compiles the project, assembles the `.app` bundle, and signs it with hardened runtime.

## Install

```bash
cp -r "build/Mika+ScreenSnap.app" /Applications/
```

## Run

```bash
open "build/Mika+ScreenSnap.app"
```

> **Note:** Always run via the `.app` bundle, not `swift run`, to ensure proper bundle identifier and window activation.

## Project Structure

```
Sources/
├── MikaScreenSnapApp.swift      # App entry point & menubar
├── CaptureEngine.swift          # Screenshot capture (ScreenCaptureKit)
├── HotkeyManager.swift          # Global hotkeys (Carbon)
├── AreaSelectionOverlay.swift   # Area selection UI
├── ClipboardManager.swift       # Clipboard & file save
├── AnnotationModel.swift        # Annotation data models
├── AnnotationCanvasView.swift   # Drawing canvas (NSView)
├── AnnotationRenderer.swift     # Rendering engine (CGContext)
├── AnnotationToolbar.swift      # Toolbar UI (SwiftUI)
└── AnnotationEditorWindow.swift # Editor window controller
```

## License

[MIT](LICENSE)
