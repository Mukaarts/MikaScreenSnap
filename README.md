# Mika+ScreenSnap

A lightweight macOS menubar screenshot tool with a professional annotation editor. Capture your screen, annotate it with 10 tools, and copy or save the result — all without leaving your workflow.

## Features

- **Menubar App** — lives in your menubar, no Dock icon
- **Capture Modes**
  - Full Screen (`Ctrl+Shift+Cmd+3`)
  - Area Selection (`Ctrl+Shift+Cmd+4`)
  - Window (`Ctrl+Shift+Cmd+5`)
- **Annotation Editor** — opens automatically after each capture
  - **Drawing Tools:** Arrow, Rectangle, Ellipse, Line, Freehand
  - **Text Tool:** Click to place editable text with background pill
  - **Effect Tools:** Highlight (yellow overlay), Blur (Gaussian), Pixelate
  - **Selection Tool:** Click to select, drag to move, 8 resize handles, Delete to remove
  - **Shift Constraints:** 45-degree snap (Arrow/Line), square (Rectangle), circle (Ellipse)
  - **Freehand:** Smooth Catmull-Rom curves
  - 6 color presets + custom color picker
  - 3 stroke widths (2/4/6px)
  - Undo / Redo (`Cmd+Z` / `Cmd+Shift+Z`)
- **Zoom & Pan**
  - `Cmd+=` / `Cmd+-` / `Cmd+0` (fit)
  - Trackpad pinch-to-zoom
  - `Space+Drag` to pan
- **Export**
  - Copy to clipboard (`Cmd+C`)
  - Save to Desktop (`Cmd+S`)
  - Save As (`Shift+Cmd+S`)
  - Escape: quick-capture (no annotations) or confirm dialog (with annotations)

## Keyboard Shortcuts

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
├── MikaScreenSnapApp.swift       # App entry point & menubar
├── CaptureEngine.swift           # Screenshot capture (ScreenCaptureKit)
├── HotkeyManager.swift           # Global hotkeys (Carbon)
├── AreaSelectionOverlay.swift     # Area selection UI
├── ClipboardManager.swift        # Clipboard & file save
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
    └── SelectionTool.swift
```

## License

[MIT](LICENSE)
