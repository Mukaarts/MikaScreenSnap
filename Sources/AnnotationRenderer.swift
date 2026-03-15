// AnnotationRenderer.swift
// MikaScreenSnap
//
// Renders the base screenshot image with all annotations composited at full resolution.
// Each Annotation draws itself via its `draw(in:baseImage:)` method.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

@MainActor
enum AnnotationRenderer {

    /// Render the base image with all annotations composited into a new full-resolution NSImage.
    ///
    /// Annotations are drawn in ascending `zIndex` order so that higher-z annotations
    /// paint on top of lower-z ones.
    static func renderFinalImage(
        baseImage: NSImage,
        annotations: [any Annotation]
    ) -> NSImage? {
        guard let cgBase = baseImage.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            return nil
        }

        let width = cgBase.width
        let height = cgBase.height
        let colorSpace = cgBase.colorSpace ?? CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        // Draw the base screenshot
        ctx.draw(cgBase, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw annotations sorted by z-order (stable sort preserves insertion order for equal zIndex)
        let sorted = annotations.sorted { $0.zIndex < $1.zIndex }
        for annotation in sorted {
            annotation.draw(in: ctx, baseImage: cgBase)
        }

        guard let result = ctx.makeImage() else { return nil }
        return NSImage(cgImage: result, size: NSSize(width: width, height: height))
    }
}
