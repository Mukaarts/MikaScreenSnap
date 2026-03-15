import AppKit
import CoreImage

@MainActor
enum AnnotationRenderer {

    /// Render all annotations onto a CGContext. Coordinates are in image space.
    static func render(
        annotations: [AnnotationItem],
        in ctx: CGContext,
        imageSize: CGSize,
        baseImage: CGImage
    ) {
        for item in annotations {
            switch item.kind {
            case .arrow(let a):
                drawArrow(in: ctx, annotation: a)
            case .rectangle(let r):
                drawRectangle(in: ctx, annotation: r)
            case .text(let t):
                drawText(in: ctx, annotation: t, imageHeight: imageSize.height)
            case .blur(let b):
                drawBlur(in: ctx, annotation: b, baseImage: baseImage)
            }
        }
    }

    // MARK: - Arrow

    static func drawArrow(in ctx: CGContext, annotation: ArrowAnnotation) {
        let start = annotation.startPoint
        let end = annotation.endPoint
        let color = annotation.color.cgColor

        ctx.saveGState()
        ctx.setStrokeColor(color)
        ctx.setLineWidth(annotation.lineWidth)
        ctx.setLineCap(.round)
        ctx.move(to: start)
        ctx.addLine(to: end)
        ctx.strokePath()

        // Arrowhead
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = max(annotation.lineWidth * 4, 14)
        let arrowAngle: CGFloat = .pi / 7

        let p1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let p2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        ctx.setFillColor(color)
        ctx.move(to: end)
        ctx.addLine(to: p1)
        ctx.addLine(to: p2)
        ctx.closePath()
        ctx.fillPath()
        ctx.restoreGState()
    }

    // MARK: - Rectangle

    static func drawRectangle(in ctx: CGContext, annotation: RectAnnotation) {
        ctx.saveGState()
        ctx.setStrokeColor(annotation.color.cgColor)
        ctx.setLineWidth(annotation.lineWidth)
        ctx.stroke(annotation.rect)
        ctx.restoreGState()
    }

    // MARK: - Text

    static func drawText(in ctx: CGContext, annotation: TextAnnotation, imageHeight: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: annotation.font,
            .foregroundColor: annotation.color,
        ]

        let attrString = NSAttributedString(string: annotation.text, attributes: attributes)
        let textSize = attrString.size()

        // Background pill
        let padding: CGFloat = 4
        let bgRect = CGRect(
            x: annotation.position.x - padding,
            y: annotation.position.y - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )

        ctx.saveGState()
        let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
        ctx.addPath(bgPath)
        ctx.fillPath()
        ctx.restoreGState()

        // Draw text using NSGraphicsContext
        NSGraphicsContext.saveGraphicsState()
        let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsContext
        attrString.draw(at: annotation.position)
        NSGraphicsContext.restoreGraphicsState()
    }

    // MARK: - Blur

    static func drawBlur(in ctx: CGContext, annotation: BlurAnnotation, baseImage: CGImage) {
        let rect = annotation.rect
        guard rect.width > 0 && rect.height > 0 else { return }

        // Scale rect to pixel coordinates of the CGImage
        let imageW = CGFloat(baseImage.width)
        let imageH = CGFloat(baseImage.height)

        // Clamp rect to image bounds
        let clampedRect = rect.intersection(CGRect(x: 0, y: 0, width: imageW, height: imageH))
        guard !clampedRect.isNull && clampedRect.width > 0 && clampedRect.height > 0 else { return }

        guard let cropped = baseImage.cropping(to: clampedRect) else { return }

        let ciImage = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(annotation.radius, forKey: kCIInputRadiusKey)

        let ciContext = CIContext()
        guard let output = filter.outputImage,
              let blurred = ciContext.createCGImage(output, from: ciImage.extent) else { return }

        ctx.saveGState()
        ctx.clip(to: clampedRect)
        ctx.draw(blurred, in: clampedRect)
        ctx.restoreGState()
    }

    // MARK: - Final Export

    /// Render the base image with all annotations to a new NSImage at full resolution.
    static func renderFinalImage(baseImage: NSImage, annotations: [AnnotationItem]) -> NSImage? {
        guard let cgBase = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
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
        ) else { return nil }

        // Draw base image
        ctx.draw(cgBase, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw annotations in image pixel space
        let imageSize = CGSize(width: width, height: height)
        render(annotations: annotations, in: ctx, imageSize: imageSize, baseImage: cgBase)

        guard let resultCGImage = ctx.makeImage() else { return nil }
        return NSImage(cgImage: resultCGImage, size: NSSize(width: width, height: height))
    }
}
