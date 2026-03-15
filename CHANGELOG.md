# Changelog

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
