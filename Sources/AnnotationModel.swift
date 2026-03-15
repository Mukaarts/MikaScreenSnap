import AppKit

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow
    case rectangle
    case text
    case blur

    var id: String { rawValue }

    var label: String {
        switch self {
        case .arrow: "Arrow"
        case .rectangle: "Rectangle"
        case .text: "Text"
        case .blur: "Blur"
        }
    }

    var systemImage: String {
        switch self {
        case .arrow: "arrow.up.right"
        case .rectangle: "rectangle"
        case .text: "textformat"
        case .blur: "eye.slash"
        }
    }
}

struct AnnotationItem: Identifiable {
    let id: UUID
    var kind: AnnotationKind

    init(kind: AnnotationKind) {
        self.id = UUID()
        self.kind = kind
    }
}

enum AnnotationKind {
    case arrow(ArrowAnnotation)
    case rectangle(RectAnnotation)
    case text(TextAnnotation)
    case blur(BlurAnnotation)
}

struct ArrowAnnotation {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: NSColor
    var lineWidth: CGFloat

    init(startPoint: CGPoint, endPoint: CGPoint, color: NSColor = .red, lineWidth: CGFloat = 3.0) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.lineWidth = lineWidth
    }
}

struct RectAnnotation {
    var rect: CGRect
    var color: NSColor
    var lineWidth: CGFloat

    init(rect: CGRect, color: NSColor = .red, lineWidth: CGFloat = 2.0) {
        self.rect = rect
        self.color = color
        self.lineWidth = lineWidth
    }
}

struct TextAnnotation {
    var position: CGPoint
    var text: String
    var font: NSFont
    var color: NSColor

    init(position: CGPoint, text: String, font: NSFont = .systemFont(ofSize: 16, weight: .bold), color: NSColor = .red) {
        self.position = position
        self.text = text
        self.font = font
        self.color = color
    }
}

struct BlurAnnotation {
    var rect: CGRect
    var radius: CGFloat

    init(rect: CGRect, radius: CGFloat = 15.0) {
        self.rect = rect
        self.radius = radius
    }
}

@Observable
@MainActor
final class AnnotationDocument {
    var annotations: [AnnotationItem] = []
    private var undoStack: [[AnnotationItem]] = []
    private var redoStack: [[AnnotationItem]] = []

    var selectedTool: AnnotationTool = .arrow
    var currentColor: NSColor = .red
    var currentLineWidth: CGFloat = 3.0

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    var onChange: (() -> Void)?

    private func pushUndo() {
        undoStack.append(annotations)
        redoStack.removeAll()
    }

    func addAnnotation(_ item: AnnotationItem) {
        pushUndo()
        annotations.append(item)
        onChange?()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = previous
        onChange?()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
        onChange?()
    }
}
