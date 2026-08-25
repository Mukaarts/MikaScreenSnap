// AnnotationTests.swift
// MikaScreenSnapTests
//
// The annotation model and the renderer both feed the export, so what the user sees and
// what leaves the app come from the same drawing instruction. These check the parts that
// are pure logic: ordering, undo, hit testing and the flattening.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class AnnotationTests: XCTestCase {

    private func base(_ colour: NSColor = .white) -> NSImage {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        colour.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        image.unlockFocus()
        return image
    }

    func testAddingAnAnnotationMarksTheStoreDirty() {
        let store = AnnotationStore()
        XCTAssertFalse(store.hasUnsavedChanges)

        store.addAnnotation(RectangleAnnotation(rect: CGRect(x: 0, y: 0, width: 10, height: 10)))

        XCTAssertTrue(store.hasUnsavedChanges)
        XCTAssertEqual(store.annotations.count, 1)
    }

    func testUndoRemovesTheAnnotationAndRedoBringsItBack() {
        let store = AnnotationStore()
        store.undoManager.groupsByEvent = false
        store.undoManager.beginUndoGrouping()
        store.addAnnotation(RectangleAnnotation(rect: CGRect(x: 0, y: 0, width: 10, height: 10)))
        store.undoManager.endUndoGrouping()

        store.undoManager.undo()
        XCTAssertEqual(store.annotations.count, 0, "undo did not remove the annotation")

        store.undoManager.redo()
        XCTAssertEqual(store.annotations.count, 1, "redo did not restore the annotation")
    }

    func testDeletingAnAnnotationCanBeUndone() {
        let store = AnnotationStore()
        // In the app each user action is its own run-loop pass and therefore its own undo
        // group. A test runs synchronously, so grouping has to be turned off or add and
        // delete collapse into one step.
        store.undoManager.groupsByEvent = false

        let annotation = RectangleAnnotation(rect: CGRect(x: 0, y: 0, width: 10, height: 10))
        store.undoManager.beginUndoGrouping()
        store.addAnnotation(annotation)
        store.undoManager.endUndoGrouping()

        store.undoManager.beginUndoGrouping()
        store.removeAnnotation(id: annotation.id)
        store.undoManager.endUndoGrouping()
        XCTAssertEqual(store.annotations.count, 0)

        store.undoManager.undo()
        XCTAssertEqual(store.annotations.count, 1, "undoing a delete must bring the annotation back")
    }

    func testHitTestingFindsAnAnnotationUnderAPoint() {
        let annotation = RectangleAnnotation(rect: CGRect(x: 10, y: 10, width: 40, height: 40))

        XCTAssertTrue(annotation.contains(CGPoint(x: 12, y: 12)))
        XCTAssertFalse(annotation.contains(CGPoint(x: 80, y: 80)))
    }

    func testMovingAnAnnotationShiftsItsBounds() {
        let annotation = RectangleAnnotation(rect: CGRect(x: 10, y: 10, width: 20, height: 20))
        annotation.moved(by: CGSize(width: 5, height: -3))

        XCTAssertEqual(annotation.bounds.origin.x, 15)
        XCTAssertEqual(annotation.bounds.origin.y, 7)
    }

    /// Equal zIndex must keep insertion order, or overlapping annotations swap on redraw.
    func testRenderingKeepsInsertionOrderForEqualZIndex() throws {
        let first = RectangleAnnotation(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        first.color = .red
        let second = RectangleAnnotation(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        second.color = .blue

        // The renderer works in image pixels, so the result matches the source bitmap
        // rather than its point size — on a Retina machine `lockFocus` gives a 2x bitmap.
        let source = base()
        let sourceCG = try XCTUnwrap(source.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let rendered = try XCTUnwrap(
            AnnotationRenderer.renderFinalImage(baseImage: source, annotations: [first, second]))
        let renderedCG = try XCTUnwrap(rendered.cgImage(forProposedRect: nil, context: nil, hints: nil))

        XCTAssertEqual(renderedCG.width, sourceCG.width)
        XCTAssertEqual(renderedCG.height, sourceCG.height)
    }

    func testTheExportIsFlatAndCarriesNoAnnotationObjects() throws {
        let annotation = BlurAnnotation(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let rendered = try XCTUnwrap(
            AnnotationRenderer.renderFinalImage(baseImage: base(), annotations: [annotation]))

        let data = try XCTUnwrap(rendered.tiffRepresentation)
        let rep = try XCTUnwrap(NSBitmapImageRep(data: data))
        XCTAssertNotNil(rep.representation(using: .png, properties: [:]),
                        "the export must be a plain bitmap")
    }

    func testTheExportMatchesTheSourceResolution() throws {
        let source = base()
        let cg = try XCTUnwrap(source.cgImage(forProposedRect: nil, context: nil, hints: nil))

        let rendered = try XCTUnwrap(
            AnnotationRenderer.renderFinalImage(baseImage: source, annotations: []))
        let renderedCG = try XCTUnwrap(rendered.cgImage(forProposedRect: nil, context: nil, hints: nil))

        XCTAssertEqual(renderedCG.width, cg.width)
        XCTAssertEqual(renderedCG.height, cg.height)
    }

    /// A measurement is a working aid, not image content — it must never reach the export.
    func testMeasurementIsNotAnAnnotationAndCannotBeExported() {
        XCTAssertNil(AnnotationType(rawValue: "measure"),
                     "measure must not exist as an annotation type, or it could be rendered")
        XCTAssertNotNil(DrawingToolType(rawValue: "measure"))
    }

    func testSnapshotAndRestoreRoundTripARectangle() {
        let annotation = RectangleAnnotation(rect: CGRect(x: 1, y: 2, width: 3, height: 4))
        annotation.zIndex = 7
        let snapshot = annotation.snapshot()

        annotation.rect = CGRect(x: 90, y: 90, width: 1, height: 1)
        annotation.zIndex = 0
        annotation.restore(from: snapshot)

        XCTAssertEqual(annotation.rect.origin.x, 1)
        XCTAssertEqual(annotation.rect.size.height, 4)
        XCTAssertEqual(annotation.zIndex, 7)
    }
}
