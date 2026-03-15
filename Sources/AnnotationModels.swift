// AnnotationModels.swift
// MikaScreenSnap
//
// Complete annotation model layer for the screenshot annotation editor.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import CoreImage

// MARK: - AnnotationType

enum AnnotationType: String, CaseIterable, Sendable {
    case arrow
    case rectangle
    case ellipse
    case line
    case freehand
    case text
    case highlight
    case blur
    case pixelate

    var systemImage: String {
        switch self {
        case .arrow:     return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .ellipse:   return "oval"
        case .line:      return "line.diagonal"
        case .freehand:  return "scribble"
        case .text:      return "textformat"
        case .highlight: return "highlighter"
        case .blur:      return "eye.slash"
        case .pixelate:  return "squareshape.split.3x3"
        }
    }

    var shortcutKey: Character {
        switch self {
        case .arrow:     return "a"
        case .rectangle: return "r"
        case .ellipse:   return "e"
        case .line:      return "l"
        case .freehand:  return "f"
        case .text:      return "t"
        case .highlight: return "h"
        case .blur:      return "b"
        case .pixelate:  return "p"
        }
    }
}

// MARK: - DrawingToolType

enum DrawingToolType: String, CaseIterable, Identifiable, Sendable {
    case select
    case arrow
    case rectangle
    case ellipse
    case line
    case freehand
    case text
    case highlight
    case blur
    case pixelate

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .select:    return "cursorarrow"
        case .arrow:     return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .ellipse:   return "oval"
        case .line:      return "line.diagonal"
        case .freehand:  return "scribble"
        case .text:      return "textformat"
        case .highlight: return "highlighter"
        case .blur:      return "eye.slash"
        case .pixelate:  return "squareshape.split.3x3"
        }
    }

    var label: String {
        switch self {
        case .select:    return "Select"
        case .arrow:     return "Arrow"
        case .rectangle: return "Rectangle"
        case .ellipse:   return "Ellipse"
        case .line:      return "Line"
        case .freehand:  return "Freehand"
        case .text:      return "Text"
        case .highlight: return "Highlight"
        case .blur:      return "Blur"
        case .pixelate:  return "Pixelate"
        }
    }
}

// MARK: - AnnotationSnapshot

struct AnnotationSnapshot: Sendable {
    let id: UUID
    let type: AnnotationType
    let data: [String: any Sendable]
}

// MARK: - Annotation Protocol

@MainActor
protocol Annotation: AnyObject, Identifiable {
    var id: UUID { get }
    var annotationType: AnnotationType { get }
    var bounds: CGRect { get }
    var color: NSColor { get set }
    var strokeWidth: CGFloat { get set }
    var isSelected: Bool { get set }
    var zIndex: Int { get set }

    func contains(_ point: CGPoint) -> Bool
    func draw(in ctx: CGContext, baseImage: CGImage?)
    func moved(by delta: CGSize)
    func resized(from oldBounds: CGRect, to newBounds: CGRect)
    func snapshot() -> AnnotationSnapshot
    func restore(from snapshot: AnnotationSnapshot)
}

// MARK: - Geometry Helpers

private func pointToSegmentDistance(_ point: CGPoint, segmentStart: CGPoint, segmentEnd: CGPoint) -> CGFloat {
    let dx = segmentEnd.x - segmentStart.x
    let dy = segmentEnd.y - segmentStart.y
    let lengthSq = dx * dx + dy * dy

    if lengthSq == 0 {
        let px = point.x - segmentStart.x
        let py = point.y - segmentStart.y
        return sqrt(px * px + py * py)
    }

    var t = ((point.x - segmentStart.x) * dx + (point.y - segmentStart.y) * dy) / lengthSq
    t = max(0, min(1, t))

    let projX = segmentStart.x + t * dx
    let projY = segmentStart.y + t * dy
    let px = point.x - projX
    let py = point.y - projY
    return sqrt(px * px + py * py)
}

private func mapPoint(_ point: CGPoint, from oldBounds: CGRect, to newBounds: CGRect) -> CGPoint {
    guard oldBounds.width > 0, oldBounds.height > 0 else { return point }
    let nx = (point.x - oldBounds.origin.x) / oldBounds.width
    let ny = (point.y - oldBounds.origin.y) / oldBounds.height
    return CGPoint(
        x: newBounds.origin.x + nx * newBounds.width,
        y: newBounds.origin.y + ny * newBounds.height
    )
}

private func mapRect(_ rect: CGRect, from oldBounds: CGRect, to newBounds: CGRect) -> CGRect {
    let origin = mapPoint(rect.origin, from: oldBounds, to: newBounds)
    let corner = mapPoint(
        CGPoint(x: rect.maxX, y: rect.maxY),
        from: oldBounds,
        to: newBounds
    )
    return CGRect(
        x: min(origin.x, corner.x),
        y: min(origin.y, corner.y),
        width: abs(corner.x - origin.x),
        height: abs(corner.y - origin.y)
    )
}

// MARK: - Snapshot Helpers

private func encodePoint(_ p: CGPoint) -> [String: any Sendable] {
    ["x": p.x, "y": p.y]
}

private func decodePoint(_ d: Any?) -> CGPoint? {
    guard let dict = d as? [String: CGFloat],
          let x = dict["x"], let y = dict["y"] else { return nil }
    return CGPoint(x: x, y: y)
}

private func encodeRect(_ r: CGRect) -> [String: any Sendable] {
    ["x": r.origin.x, "y": r.origin.y, "w": r.width, "h": r.height]
}

private func decodeRect(_ d: Any?) -> CGRect? {
    guard let dict = d as? [String: CGFloat],
          let x = dict["x"], let y = dict["y"],
          let w = dict["w"], let h = dict["h"] else { return nil }
    return CGRect(x: x, y: y, width: w, height: h)
}

private func encodeColor(_ c: NSColor) -> [String: any Sendable] {
    let rgb = c.usingColorSpace(.sRGB) ?? c
    return [
        "r": rgb.redComponent,
        "g": rgb.greenComponent,
        "b": rgb.blueComponent,
        "a": rgb.alphaComponent,
    ]
}

private func decodeColor(_ d: Any?) -> NSColor? {
    guard let dict = d as? [String: CGFloat],
          let r = dict["r"], let g = dict["g"],
          let b = dict["b"], let a = dict["a"] else { return nil }
    return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// MARK: - 1. ArrowAnnotation

@MainActor
final class ArrowAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .arrow
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: NSColor
    var strokeWidth: CGFloat
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    init(
        id: UUID = UUID(),
        startPoint: CGPoint,
        endPoint: CGPoint,
        color: NSColor = .systemRed,
        strokeWidth: CGFloat = 3.0
    ) {
        self.id = id
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.strokeWidth = strokeWidth
    }

    func contains(_ point: CGPoint) -> Bool {
        pointToSegmentDistance(point, segmentStart: startPoint, segmentEnd: endPoint) < strokeWidth + 4
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.setLineCap(.round)
        ctx.move(to: startPoint)
        ctx.addLine(to: endPoint)
        ctx.strokePath()

        // Filled triangle arrowhead
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength = max(strokeWidth * 4, 14)
        let arrowAngle: CGFloat = .pi / 7

        let p1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        let p2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )

        ctx.setFillColor(color.cgColor)
        ctx.move(to: endPoint)
        ctx.addLine(to: p1)
        ctx.addLine(to: p2)
        ctx.closePath()
        ctx.fillPath()
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        startPoint.x += delta.width
        startPoint.y += delta.height
        endPoint.x += delta.width
        endPoint.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        startPoint = mapPoint(startPoint, from: oldBounds, to: newBounds)
        endPoint = mapPoint(endPoint, from: oldBounds, to: newBounds)
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "startPoint": encodePoint(startPoint),
            "endPoint": encodePoint(endPoint),
            "color": encodeColor(color),
            "strokeWidth": strokeWidth,
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let p = decodePoint(snapshot.data["startPoint"]) { startPoint = p }
        if let p = decodePoint(snapshot.data["endPoint"]) { endPoint = p }
        if let c = decodeColor(snapshot.data["color"]) { color = c }
        if let w = snapshot.data["strokeWidth"] as? CGFloat { strokeWidth = w }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 2. RectangleAnnotation

@MainActor
final class RectangleAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .rectangle
    var rect: CGRect
    var color: NSColor
    var strokeWidth: CGFloat
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect { rect }

    init(
        id: UUID = UUID(),
        rect: CGRect,
        color: NSColor = .systemRed,
        strokeWidth: CGFloat = 3.0
    ) {
        self.id = id
        self.rect = rect
        self.color = color
        self.strokeWidth = strokeWidth
    }

    func contains(_ point: CGPoint) -> Bool {
        let threshold = strokeWidth + 4
        let outer = rect.insetBy(dx: -threshold, dy: -threshold)
        let inner = rect.insetBy(dx: threshold, dy: threshold)
        return outer.contains(point) && !inner.contains(point)
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.stroke(rect)
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        rect.origin.x += delta.width
        rect.origin.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        rect = mapRect(rect, from: oldBounds, to: newBounds)
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "rect": encodeRect(rect),
            "color": encodeColor(color),
            "strokeWidth": strokeWidth,
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let r = decodeRect(snapshot.data["rect"]) { rect = r }
        if let c = decodeColor(snapshot.data["color"]) { color = c }
        if let w = snapshot.data["strokeWidth"] as? CGFloat { strokeWidth = w }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 3. EllipseAnnotation

@MainActor
final class EllipseAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .ellipse
    var rect: CGRect
    var color: NSColor
    var strokeWidth: CGFloat
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect { rect }

    init(
        id: UUID = UUID(),
        rect: CGRect,
        color: NSColor = .systemRed,
        strokeWidth: CGFloat = 3.0
    ) {
        self.id = id
        self.rect = rect
        self.color = color
        self.strokeWidth = strokeWidth
    }

    func contains(_ point: CGPoint) -> Bool {
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2
        guard rx > 0, ry > 0 else { return false }

        let nx = (point.x - cx) / rx
        let ny = (point.y - cy) / ry
        let dist = sqrt(nx * nx + ny * ny)
        let threshold = (strokeWidth + 4) / min(rx, ry)
        return abs(dist - 1.0) < threshold
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.strokeEllipse(in: rect)
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        rect.origin.x += delta.width
        rect.origin.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        rect = mapRect(rect, from: oldBounds, to: newBounds)
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "rect": encodeRect(rect),
            "color": encodeColor(color),
            "strokeWidth": strokeWidth,
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let r = decodeRect(snapshot.data["rect"]) { rect = r }
        if let c = decodeColor(snapshot.data["color"]) { color = c }
        if let w = snapshot.data["strokeWidth"] as? CGFloat { strokeWidth = w }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 4. LineAnnotation

@MainActor
final class LineAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .line
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: NSColor
    var strokeWidth: CGFloat
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    init(
        id: UUID = UUID(),
        startPoint: CGPoint,
        endPoint: CGPoint,
        color: NSColor = .systemRed,
        strokeWidth: CGFloat = 3.0
    ) {
        self.id = id
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.strokeWidth = strokeWidth
    }

    func contains(_ point: CGPoint) -> Bool {
        pointToSegmentDistance(point, segmentStart: startPoint, segmentEnd: endPoint) < strokeWidth + 4
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.setLineCap(.round)
        ctx.move(to: startPoint)
        ctx.addLine(to: endPoint)
        ctx.strokePath()
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        startPoint.x += delta.width
        startPoint.y += delta.height
        endPoint.x += delta.width
        endPoint.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        startPoint = mapPoint(startPoint, from: oldBounds, to: newBounds)
        endPoint = mapPoint(endPoint, from: oldBounds, to: newBounds)
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "startPoint": encodePoint(startPoint),
            "endPoint": encodePoint(endPoint),
            "color": encodeColor(color),
            "strokeWidth": strokeWidth,
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let p = decodePoint(snapshot.data["startPoint"]) { startPoint = p }
        if let p = decodePoint(snapshot.data["endPoint"]) { endPoint = p }
        if let c = decodeColor(snapshot.data["color"]) { color = c }
        if let w = snapshot.data["strokeWidth"] as? CGFloat { strokeWidth = w }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 5. FreehandAnnotation

@MainActor
final class FreehandAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .freehand
    var points: [CGPoint]
    var color: NSColor
    var strokeWidth: CGFloat
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect {
        guard let first = points.first else { return .zero }
        var minX = first.x, minY = first.y
        var maxX = first.x, maxY = first.y
        for p in points {
            minX = min(minX, p.x)
            minY = min(minY, p.y)
            maxX = max(maxX, p.x)
            maxY = max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    init(
        id: UUID = UUID(),
        points: [CGPoint],
        color: NSColor = .systemRed,
        strokeWidth: CGFloat = 3.0
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.strokeWidth = strokeWidth
    }

    func contains(_ point: CGPoint) -> Bool {
        let threshold = strokeWidth + 4
        guard points.count >= 2 else {
            if let only = points.first {
                let dx = point.x - only.x
                let dy = point.y - only.y
                return sqrt(dx * dx + dy * dy) < threshold
            }
            return false
        }
        for i in 0..<(points.count - 1) {
            if pointToSegmentDistance(point, segmentStart: points[i], segmentEnd: points[i + 1]) < threshold {
                return true
            }
        }
        return false
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        guard points.count >= 2 else { return }

        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        if points.count == 2 {
            ctx.move(to: points[0])
            ctx.addLine(to: points[1])
        } else {
            // Catmull-Rom to Bezier smoothing
            ctx.move(to: points[0])

            for i in 0..<points.count - 1 {
                let p0 = points[max(i - 1, 0)]
                let p1 = points[i]
                let p2 = points[min(i + 1, points.count - 1)]
                let p3 = points[min(i + 2, points.count - 1)]

                // Convert Catmull-Rom segment to cubic Bezier control points
                let cp1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) / 6.0,
                    y: p1.y + (p2.y - p0.y) / 6.0
                )
                let cp2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) / 6.0,
                    y: p2.y - (p3.y - p1.y) / 6.0
                )

                ctx.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }

        ctx.strokePath()
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        for i in points.indices {
            points[i].x += delta.width
            points[i].y += delta.height
        }
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        for i in points.indices {
            points[i] = mapPoint(points[i], from: oldBounds, to: newBounds)
        }
    }

    func snapshot() -> AnnotationSnapshot {
        let encoded: [[String: any Sendable]] = points.map { encodePoint($0) }
        return AnnotationSnapshot(id: id, type: annotationType, data: [
            "points": encoded,
            "color": encodeColor(color),
            "strokeWidth": strokeWidth,
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let arr = snapshot.data["points"] as? [[String: CGFloat]] {
            points = arr.compactMap { decodePoint($0) }
        }
        if let c = decodeColor(snapshot.data["color"]) { color = c }
        if let w = snapshot.data["strokeWidth"] as? CGFloat { strokeWidth = w }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 6. TextAnnotation

@MainActor
final class TextAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .text
    var position: CGPoint
    var text: String
    var font: NSFont
    var color: NSColor
    var strokeWidth: CGFloat = 0
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect {
        let size = textSize
        return CGRect(origin: position, size: size)
    }

    private var textSize: CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        return attrString.size()
    }

    init(
        id: UUID = UUID(),
        position: CGPoint,
        text: String,
        font: NSFont = NSFont(name: "SF Pro", size: 16)
            ?? NSFont.systemFont(ofSize: 16, weight: .bold),
        color: NSColor = .systemRed
    ) {
        self.id = id
        self.position = position
        self.text = text
        self.font = font
        self.color = color
    }

    func contains(_ point: CGPoint) -> Bool {
        bounds.contains(point)
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let size = attrString.size()

        // Semi-transparent black background pill
        let padding: CGFloat = 4
        let bgRect = CGRect(
            x: position.x - padding,
            y: position.y - padding,
            width: size.width + padding * 2,
            height: size.height + padding * 2
        )

        ctx.saveGState()
        let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
        ctx.addPath(bgPath)
        ctx.fillPath()
        ctx.restoreGState()

        // Draw text via NSGraphicsContext
        NSGraphicsContext.saveGraphicsState()
        let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsContext
        attrString.draw(at: position)
        NSGraphicsContext.restoreGraphicsState()
    }

    func moved(by delta: CGSize) {
        position.x += delta.width
        position.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        position = mapPoint(position, from: oldBounds, to: newBounds)
        // Scale font proportionally
        let scale = newBounds.width / max(oldBounds.width, 1)
        let newSize = max(font.pointSize * scale, 8)
        font = NSFont(descriptor: font.fontDescriptor, size: newSize) ?? font
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "position": encodePoint(position),
            "text": text,
            "fontSize": font.pointSize,
            "fontName": font.fontName,
            "color": encodeColor(color),
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let p = decodePoint(snapshot.data["position"]) { position = p }
        if let t = snapshot.data["text"] as? String { text = t }
        if let size = snapshot.data["fontSize"] as? CGFloat,
           let name = snapshot.data["fontName"] as? String {
            font = NSFont(name: name, size: size)
                ?? NSFont.systemFont(ofSize: size, weight: .bold)
        }
        if let c = decodeColor(snapshot.data["color"]) { color = c }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 7. HighlightAnnotation

@MainActor
final class HighlightAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .highlight
    var rect: CGRect
    var color: NSColor
    var strokeWidth: CGFloat = 0
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect { rect }

    init(
        id: UUID = UUID(),
        rect: CGRect,
        color: NSColor = NSColor.yellow.withAlphaComponent(0.3)
    ) {
        self.id = id
        self.rect = rect
        self.color = color
    }

    func contains(_ point: CGPoint) -> Bool {
        rect.contains(point)
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        rect.origin.x += delta.width
        rect.origin.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        rect = mapRect(rect, from: oldBounds, to: newBounds)
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "rect": encodeRect(rect),
            "color": encodeColor(color),
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let r = decodeRect(snapshot.data["rect"]) { rect = r }
        if let c = decodeColor(snapshot.data["color"]) { color = c }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 8. BlurAnnotation

@MainActor
final class BlurAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .blur
    var rect: CGRect
    var radius: CGFloat
    var color: NSColor = .clear
    var strokeWidth: CGFloat = 0
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect { rect }

    init(
        id: UUID = UUID(),
        rect: CGRect,
        radius: CGFloat = 15.0
    ) {
        self.id = id
        self.rect = rect
        self.radius = radius
    }

    func contains(_ point: CGPoint) -> Bool {
        rect.contains(point)
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        guard let baseImage, rect.width > 0, rect.height > 0 else { return }

        let imageBounds = CGRect(x: 0, y: 0, width: baseImage.width, height: baseImage.height)
        let clampedRect = rect.intersection(imageBounds)
        guard !clampedRect.isNull, clampedRect.width > 0, clampedRect.height > 0 else { return }

        guard let cropped = baseImage.cropping(to: clampedRect) else { return }

        let ciImage = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        let ciContext = CIContext()
        guard let output = filter.outputImage,
              let blurred = ciContext.createCGImage(output, from: ciImage.extent) else { return }

        ctx.saveGState()
        ctx.clip(to: clampedRect)
        ctx.draw(blurred, in: clampedRect)
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        rect.origin.x += delta.width
        rect.origin.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        rect = mapRect(rect, from: oldBounds, to: newBounds)
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "rect": encodeRect(rect),
            "radius": radius,
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let r = decodeRect(snapshot.data["rect"]) { rect = r }
        if let rad = snapshot.data["radius"] as? CGFloat { radius = rad }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - 9. PixelateAnnotation

@MainActor
final class PixelateAnnotation: Annotation {
    let id: UUID
    let annotationType: AnnotationType = .pixelate
    var rect: CGRect
    var blockSize: CGFloat
    var color: NSColor = .clear
    var strokeWidth: CGFloat = 0
    var isSelected: Bool = false
    var zIndex: Int = 0

    var bounds: CGRect { rect }

    init(
        id: UUID = UUID(),
        rect: CGRect,
        blockSize: CGFloat = 10.0
    ) {
        self.id = id
        self.rect = rect
        self.blockSize = blockSize
    }

    func contains(_ point: CGPoint) -> Bool {
        rect.contains(point)
    }

    func draw(in ctx: CGContext, baseImage: CGImage?) {
        guard let baseImage, rect.width > 0, rect.height > 0 else { return }

        let imageBounds = CGRect(x: 0, y: 0, width: baseImage.width, height: baseImage.height)
        let clampedRect = rect.intersection(imageBounds)
        guard !clampedRect.isNull, clampedRect.width > 0, clampedRect.height > 0 else { return }

        guard let cropped = baseImage.cropping(to: clampedRect) else { return }

        let ciImage = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIPixellate") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(blockSize, forKey: kCIInputScaleKey)

        // Center the pixellation grid on the image center
        let center = CIVector(x: ciImage.extent.midX, y: ciImage.extent.midY)
        filter.setValue(center, forKey: kCIInputCenterKey)

        let ciContext = CIContext()
        guard let output = filter.outputImage,
              let pixelated = ciContext.createCGImage(output, from: ciImage.extent) else { return }

        ctx.saveGState()
        ctx.clip(to: clampedRect)
        ctx.draw(pixelated, in: clampedRect)
        ctx.restoreGState()
    }

    func moved(by delta: CGSize) {
        rect.origin.x += delta.width
        rect.origin.y += delta.height
    }

    func resized(from oldBounds: CGRect, to newBounds: CGRect) {
        rect = mapRect(rect, from: oldBounds, to: newBounds)
    }

    func snapshot() -> AnnotationSnapshot {
        AnnotationSnapshot(id: id, type: annotationType, data: [
            "rect": encodeRect(rect),
            "blockSize": blockSize,
            "isSelected": isSelected,
            "zIndex": zIndex,
        ])
    }

    func restore(from snapshot: AnnotationSnapshot) {
        if let r = decodeRect(snapshot.data["rect"]) { rect = r }
        if let bs = snapshot.data["blockSize"] as? CGFloat { blockSize = bs }
        if let s = snapshot.data["isSelected"] as? Bool { isSelected = s }
        if let z = snapshot.data["zIndex"] as? Int { zIndex = z }
    }
}

// MARK: - AnnotationStore

@Observable
@MainActor
final class AnnotationStore {
    var annotations: [any Annotation] = []
    var selectedAnnotationID: UUID?
    var currentColor: NSColor = .systemRed
    var currentStrokeWidth: CGFloat = 3.0
    var selectedTool: DrawingToolType = .arrow
    var zoomLevel: CGFloat = 1.0
    var panOffset: CGPoint = .zero
    var hasUnsavedChanges: Bool = false

    let undoManager: UndoManager = UndoManager()

    var selectedAnnotation: (any Annotation)? {
        guard let id = selectedAnnotationID else { return nil }
        return annotations.first { $0.id == id }
    }

    // MARK: - Mutations

    func addAnnotation(_ annotation: any Annotation) {
        let id = annotation.id
        annotations.append(annotation)
        hasUnsavedChanges = true

        undoManager.registerUndo(withTarget: self) { [weak self] store in
            MainActor.assumeIsolated {
                store.removeAnnotationWithoutUndo(id: id)
                // Register redo
                store.undoManager.registerUndo(withTarget: store) { store2 in
                    MainActor.assumeIsolated {
                        store2.addAnnotation(annotation)
                    }
                }
            }
        }
    }

    func removeAnnotation(id: UUID) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        let removed = annotations[index]
        let removedIndex = index
        annotations.remove(at: index)
        hasUnsavedChanges = true

        if selectedAnnotationID == id {
            selectedAnnotationID = nil
        }

        undoManager.registerUndo(withTarget: self) { store in
            MainActor.assumeIsolated {
                store.annotations.insert(removed, at: min(removedIndex, store.annotations.count))
                store.hasUnsavedChanges = true
                // Register redo
                store.undoManager.registerUndo(withTarget: store) { store2 in
                    MainActor.assumeIsolated {
                        store2.removeAnnotation(id: id)
                    }
                }
            }
        }
    }

    func modifyAnnotation(id: UUID, action: (any Annotation) -> Void) {
        guard let annotation = annotations.first(where: { $0.id == id }) else { return }
        let beforeSnapshot = annotation.snapshot()
        action(annotation)
        hasUnsavedChanges = true

        undoManager.registerUndo(withTarget: self) { store in
            MainActor.assumeIsolated {
                guard let ann = store.annotations.first(where: { $0.id == id }) else { return }
                let redoSnapshot = ann.snapshot()
                ann.restore(from: beforeSnapshot)
                store.hasUnsavedChanges = true
                // Register redo
                store.undoManager.registerUndo(withTarget: store) { store2 in
                    MainActor.assumeIsolated {
                        guard let ann2 = store2.annotations.first(where: { $0.id == id }) else { return }
                        ann2.restore(from: redoSnapshot)
                        store2.hasUnsavedChanges = true
                    }
                }
            }
        }
    }

    func selectAnnotation(at point: CGPoint) {
        // Reverse z-order hit test (highest zIndex first, then last-in-array first)
        let sorted = annotations.enumerated().sorted { lhs, rhs in
            if lhs.element.zIndex != rhs.element.zIndex {
                return lhs.element.zIndex > rhs.element.zIndex
            }
            return lhs.offset > rhs.offset
        }

        for (_, annotation) in sorted {
            if annotation.contains(point) {
                // Deselect previous
                if let prevID = selectedAnnotationID,
                   let prev = annotations.first(where: { $0.id == prevID }) {
                    prev.isSelected = false
                }
                annotation.isSelected = true
                selectedAnnotationID = annotation.id
                return
            }
        }

        deselectAll()
    }

    func deselectAll() {
        if let prevID = selectedAnnotationID,
           let prev = annotations.first(where: { $0.id == prevID }) {
            prev.isSelected = false
        }
        selectedAnnotationID = nil
    }

    func deleteSelected() {
        guard let id = selectedAnnotationID else { return }
        removeAnnotation(id: id)
    }

    // MARK: - Snapshot support for SelectionTool drag operations

    func snapshotAnnotations() -> [AnnotationSnapshot] {
        annotations.map { $0.snapshot() }
    }

    func registerUndoFromSnapshot(_ snapshots: [AnnotationSnapshot]) {
        undoManager.registerUndo(withTarget: self) { store in
            MainActor.assumeIsolated {
                let redoSnapshots = store.snapshotAnnotations()
                for snap in snapshots {
                    if let ann = store.annotations.first(where: { $0.id == snap.id }) {
                        ann.restore(from: snap)
                    }
                }
                store.hasUnsavedChanges = true
                store.undoManager.registerUndo(withTarget: store) { store2 in
                    MainActor.assumeIsolated {
                        store2.registerUndoFromSnapshot(redoSnapshots)
                    }
                }
            }
        }
    }

    // MARK: - Internal

    private func removeAnnotationWithoutUndo(id: UUID) {
        annotations.removeAll { $0.id == id }
        hasUnsavedChanges = true
        if selectedAnnotationID == id {
            selectedAnnotationID = nil
        }
    }
}
