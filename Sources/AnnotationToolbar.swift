// AnnotationToolbar.swift
// MikaScreenSnap
//
// Top toolbar for the annotation editor: tool selection, color/stroke pickers, undo/redo.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct AnnotationToolbarView: View {
    let store: AnnotationStore
    let onToolChanged: () -> Void

    private let presetColors: [NSColor] = [
        .systemRed, .systemBlue, .systemGreen, .yellow, .white, .black,
    ]

    private let drawingTools: [DrawingToolType] = [
        .arrow, .rectangle, .ellipse, .line, .freehand,
    ]

    private let effectTools: [DrawingToolType] = [
        .highlight, .blur, .pixelate,
    ]

    private let strokeOptions: [(label: String, width: CGFloat)] = [
        ("Thin", 2),
        ("Medium", 4),
        ("Thick", 6),
    ]

    var body: some View {
        HStack(spacing: 12) {
            // MARK: Left — Tool groups
            toolSection

            Divider().frame(height: 24)

            // MARK: Middle — Colors
            colorSection

            Divider().frame(height: 24)

            // MARK: Middle — Stroke width
            strokeSection

            Spacer()

            // MARK: Right — Undo / Redo
            undoSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 50)
        .background(.ultraThinMaterial)
    }

    // MARK: - Tool Section

    private var toolSection: some View {
        HStack(spacing: 4) {
            // Select
            toolButton(for: .select)

            verticalDivider

            // Drawing tools
            ForEach(drawingTools) { tool in
                toolButton(for: tool)
            }

            verticalDivider

            // Text tool
            toolButton(for: .text)

            verticalDivider

            // Effect tools
            ForEach(effectTools) { tool in
                toolButton(for: tool)
            }
        }
    }

    private func toolButton(for tool: DrawingToolType) -> some View {
        Button {
            store.selectedTool = tool
            onToolChanged()
        } label: {
            Image(systemName: tool.systemImage)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .background(
            store.selectedTool == tool
                ? Color.accentColor.opacity(0.3)
                : Color.clear
        )
        .cornerRadius(6)
        .help(tool.label)
    }

    private var verticalDivider: some View {
        Divider().frame(height: 24)
    }

    // MARK: - Color Section

    private var colorSection: some View {
        HStack(spacing: 4) {
            ForEach(presetColors, id: \.self) { color in
                Circle()
                    .fill(Color(nsColor: color))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(
                                isColorSelected(color)
                                    ? Color.blue
                                    : Color.clear,
                                lineWidth: 2
                            )
                            .padding(-2)
                    )
                    .onTapGesture {
                        store.currentColor = color
                    }
            }

            // Custom color picker
            ColorPicker("", selection: customColorBinding)
                .labelsHidden()
                .frame(width: 24, height: 24)
                .help("Custom Color")
        }
    }

    private var customColorBinding: Binding<Color> {
        Binding<Color>(
            get: { Color(nsColor: store.currentColor) },
            set: { newColor in
                store.currentColor = NSColor(newColor)
            }
        )
    }

    /// Compare colors by their cgColor components, since direct NSColor equality is unreliable.
    private func isColorSelected(_ color: NSColor) -> Bool {
        guard let selectedComponents = store.currentColor.cgColor.components,
              let colorComponents = color.cgColor.components else {
            return false
        }
        guard selectedComponents.count == colorComponents.count else {
            return false
        }
        for (a, b) in zip(selectedComponents, colorComponents) {
            if abs(a - b) > 0.01 { return false }
        }
        return true
    }

    // MARK: - Stroke Width Section

    private var strokeSection: some View {
        HStack(spacing: 4) {
            ForEach(strokeOptions, id: \.label) { option in
                Button {
                    store.currentStrokeWidth = option.width
                } label: {
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: 20, height: option.width)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .background(
                    store.currentStrokeWidth == option.width
                        ? Color.accentColor.opacity(0.3)
                        : Color.clear
                )
                .cornerRadius(6)
                .help(option.label)
            }
        }
    }

    // MARK: - Undo / Redo Section

    private var undoSection: some View {
        HStack(spacing: 4) {
            Button {
                store.undoManager.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!store.undoManager.canUndo)
            .help("Undo (\u{2318}Z)")

            Button {
                store.undoManager.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!store.undoManager.canRedo)
            .help("Redo (\u{21E7}\u{2318}Z)")
        }
    }
}
