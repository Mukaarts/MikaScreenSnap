# Changelog

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
