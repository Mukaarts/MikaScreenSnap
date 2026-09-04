// AreaSelectionLabelTests.swift
// MikaScreenSnapTests
//
// The size readout of the area selection: where it lands.
//
// This is placement arithmetic on a view that only exists while the mouse is down, so
// nothing catches it in normal use — and a label drawn outside the view looks exactly
// like a label that was never drawn.
//
// One case was actually broken: a selection reaching the top of the screen. The rest are
// guards, and the sweep at the end is the property all of them are instances of.

import XCTest
import AppKit
@testable import MikaScreenSnap

@MainActor
final class AreaSelectionLabelTests: XCTestCase {

    /// A single display, the usual case.
    private let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)

    private func label(for selection: NSRect, in bounds: NSRect? = nil) -> NSRect {
        let text = AreaSelectionView.sizeLabelText(for: selection)
        return AreaSelectionView.sizeLabelRect(for: selection,
                                               in: bounds ?? screen,
                                               labelSize: AreaSelectionView.sizeLabelSize(for: text))
    }

    // MARK: - The readout itself

    func testTheReadoutNamesBothEdgeLengthsInPixels() {
        XCTAssertEqual(AreaSelectionView.sizeLabelText(for: NSRect(x: 10, y: 20, width: 640, height: 480)),
                       "640 \u{00D7} 480 px")
    }

    /// Fractional drags are the norm on a Retina display; the readout is whole pixels.
    func testTheReadoutRoundsTowardsZeroRatherThanShowingDecimals() {
        XCTAssertEqual(AreaSelectionView.sizeLabelText(for: NSRect(x: 0, y: 0, width: 640.7, height: 479.2)),
                       "640 \u{00D7} 479 px")
    }

    // MARK: - Placement

    func testItSitsBelowTheSelectionWithTheRightEdgesAligned() {
        let selection = NSRect(x: 300, y: 280, width: 1120, height: 590)
        let rect = label(for: selection)
        XCTAssertEqual(rect.maxX, selection.maxX, accuracy: 0.5,
                       "the right edges should line up")
        XCTAssertEqual(rect.maxY, selection.minY - AreaSelectionView.sizeLabelGap, accuracy: 0.5,
                       "the readout belongs just below the selection")
    }

    /// A selection dragged down to the bottom edge leaves no room underneath.
    func testItMovesAboveTheSelectionWhenThereIsNoRoomBelow() {
        let selection = NSRect(x: 400, y: 0, width: 600, height: 400)
        let rect = label(for: selection)
        XCTAssertEqual(rect.minY, selection.maxY + AreaSelectionView.sizeLabelGap, accuracy: 0.5)
        XCTAssertTrue(screen.contains(rect), "moved above but off the view: \(rect)")
    }

    /// The case the old code got wrong. With the selection against the top edge there is
    /// no room below, and the fallback "put it above" pushed the label past `bounds.maxY`
    /// — off the view, invisible, with no error anywhere. Dragging down from the menu bar
    /// hits this every time.
    func testItStaysOnTheViewWhenTheSelectionTouchesTheTopEdge() {
        let selection = NSRect(x: 400, y: 0, width: 600, height: 1080)
        let rect = label(for: selection)
        XCTAssertTrue(screen.contains(rect), "readout left the view: \(rect)")
        XCTAssertLessThanOrEqual(rect.maxY, screen.maxY)
    }

    /// A guard, not a past bug: `maxX - labelWidth` cannot overflow to the right on its
    /// own. It would the moment someone aligns the label's *left* edge with the selection
    /// instead, which is the obvious way to rewrite this.
    func testItStaysOnTheViewForANarrowSelectionAtTheRightEdge() {
        let selection = NSRect(x: 1900, y: 500, width: 20, height: 20)
        let rect = label(for: selection)
        XCTAssertTrue(screen.contains(rect), "readout left the view: \(rect)")
        XCTAssertLessThanOrEqual(rect.maxX, screen.maxX)
    }

    /// Also a guard: the old code already handled this one, by snapping the label to the
    /// selection's left edge. Keeping the case means the clamp cannot quietly drop it.
    func testItStaysOnTheViewForANarrowSelectionAtTheLeftEdge() {
        let selection = NSRect(x: 0, y: 500, width: 20, height: 20)
        let rect = label(for: selection)
        XCTAssertTrue(screen.contains(rect), "readout left the view: \(rect)")
        XCTAssertGreaterThanOrEqual(rect.minX, screen.minX)
    }

    /// A selection covering the whole screen has no outside left at all.
    func testItGoesInsideTheSelectionWhenThereIsNoOutsideLeft() {
        let rect = label(for: screen)
        XCTAssertTrue(screen.contains(rect), "readout left the view: \(rect)")
    }

    /// The sweep: whatever the drag, the readout is on the view. One assertion for the
    /// property the four cases above are each one instance of.
    func testTheReadoutIsAlwaysFullyInsideTheView() {
        let stops: [CGFloat] = [0, 1, 40, 960, 1899, 1920]
        let heights: [CGFloat] = [0, 1, 30, 540, 1079, 1080]
        for x in stops {
            for y in heights {
                for w in stops where x + w <= screen.maxX {
                    for h in heights where y + h <= screen.maxY {
                        let selection = NSRect(x: x, y: y, width: w, height: h)
                        let rect = label(for: selection)
                        XCTAssertTrue(screen.contains(rect),
                                      "selection \(selection) put the readout at \(rect)")
                    }
                }
            }
        }
    }

    // MARK: - It actually paints

    /// The symptom that started this was "the readout is on no screenshot at all", and
    /// geometry is only half of that answer: a label placed correctly still has to leave
    /// pixels behind. Drawing it into an offscreen bitmap answers that half without a
    /// running app, a permission or a window server.
    func testTheReadoutLeavesPixelsWhereItSaysItWill() throws {
        let canvas = NSRect(x: 0, y: 0, width: 400, height: 300)
        let selection = NSRect(x: 100, y: 120, width: 200, height: 120)
        let expected = label(for: selection, in: canvas)

        let rep = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 400, pixelsHigh: 300,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.white.setFill()
        canvas.fill()
        AreaSelectionView.drawSizeLabel(for: selection, in: canvas)
        NSGraphicsContext.restoreGraphicsState()

        // The plate is black at 70% over white, so its centre must be clearly dark.
        let centre = try XCTUnwrap(rep.colorAt(x: Int(expected.midX),
                                               y: rep.pixelsHigh - Int(expected.midY)))
        XCTAssertLessThan(centre.brightnessComponent, 0.5,
                          "nothing was drawn at \(expected) — the readout paints nothing")

        // And it must not have painted over the whole view while doing it.
        let corner = try XCTUnwrap(rep.colorAt(x: 5, y: 5))
        XCTAssertGreaterThan(corner.brightnessComponent, 0.9,
                             "the readout painted outside its own rectangle")
    }

    /// A second display sits at a negative origin, but the view's own bounds always start
    /// at zero — the panel takes the screen's size, not its position. Guards against a
    /// future change that passes `screen.frame` in here by mistake.
    func testItAlsoHoldsForAViewWhoseBoundsDoNotStartAtZero() {
        let odd = NSRect(x: -1920, y: 0, width: 1920, height: 1080)
        let rect = label(for: NSRect(x: -1900, y: 1060, width: 40, height: 20), in: odd)
        XCTAssertTrue(odd.contains(rect), "readout left the view: \(rect)")
    }
}
