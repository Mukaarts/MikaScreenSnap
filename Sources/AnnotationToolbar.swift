import SwiftUI

struct AnnotationToolbarView: View {
    let document: AnnotationDocument
    let onDone: () -> Void
    let onSave: () -> Void
    let onToolChanged: () -> Void

    private let presetColors: [Color] = [.red, .blue, .green, .yellow, .white, .black]

    var body: some View {
        HStack(spacing: 16) {
            // Tool selection
            toolButtons

            Divider()
                .frame(height: 24)

            // Color swatches
            colorPicker

            Divider()
                .frame(height: 24)

            // Line width
            lineWidthPicker

            Divider()
                .frame(height: 24)

            // Undo/Redo
            undoRedoButtons

            Spacer()

            // Done / Save
            actionButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var toolButtons: some View {
        HStack(spacing: 4) {
            ForEach(AnnotationTool.allCases) { tool in
                Button {
                    document.selectedTool = tool
                    onToolChanged()
                } label: {
                    Image(systemName: tool.systemImage)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .background(document.selectedTool == tool ? Color.accentColor.opacity(0.3) : Color.clear)
                .cornerRadius(6)
                .help(tool.label)
            }
        }
    }

    private var colorPicker: some View {
        HStack(spacing: 4) {
            ForEach(presetColors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(isSelected(color) ? Color.primary : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        document.currentColor = NSColor(color)
                    }
            }
        }
    }

    private func isSelected(_ color: Color) -> Bool {
        NSColor(color).cgColor.components == document.currentColor.cgColor.components
    }

    private var lineWidthPicker: some View {
        HStack(spacing: 4) {
            ForEach([
                (label: "Thin", width: CGFloat(1.5)),
                (label: "Medium", width: CGFloat(3.0)),
                (label: "Thick", width: CGFloat(5.0)),
            ], id: \.label) { option in
                Button {
                    document.currentLineWidth = option.width
                } label: {
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: 20, height: option.width + 1)
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .background(document.currentLineWidth == option.width ? Color.accentColor.opacity(0.3) : Color.clear)
                .cornerRadius(6)
                .help(option.label)
            }
        }
    }

    private var undoRedoButtons: some View {
        HStack(spacing: 4) {
            Button {
                document.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!document.canUndo)
            .help("Undo (\u{2318}Z)")

            Button {
                document.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!document.canRedo)
            .help("Redo (\u{21E7}\u{2318}Z)")
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("Save") {
                onSave()
            }
            .buttonStyle(.bordered)

            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
