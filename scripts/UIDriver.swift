#!/usr/bin/env swift
// UIDriver.swift
// MikaScreenSnap
//
// Small automation helper used by scripts/capture-marketing-shots.sh to drive
// the app while marketing screenshots are recorded. Requires Accessibility
// permission for the invoking terminal.
//
// Usage:
//   swift scripts/UIDriver.swift list [ownerSubstring]
//   swift scripts/UIDriver.swift id <ownerSubstring> <titleSubstring>
//   swift scripts/UIDriver.swift move <x> <y>
//   swift scripts/UIDriver.swift click <x> <y>
//   swift scripts/UIDriver.swift drag <x1> <y1> <x2> <y2>
//   swift scripts/UIDriver.swift key <combo>        e.g. cmd+shift+7, escape, m
//   swift scripts/UIDriver.swift drag-shot <x1> <y1> <x2> <y2> <out> [display]\n//   swift scripts/UIDriver.swift screen-shot <out> [display]\n//   swift scripts/UIDriver.swift crop <in> <out> <x> <y> <w> <h>   (points, 2x aware)
//
// All coordinates are in screen points (top-left origin), matching the values
// reported by `list`.

import AppKit
import CoreGraphics
import Foundation

// MARK: - Window listing

struct WindowInfo {
    let number: Int
    let owner: String
    let title: String
    let layer: Int
    let bounds: CGRect
}

func listWindows() -> [WindowInfo] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
        return []
    }
    return raw.compactMap { entry in
        guard let number = entry[kCGWindowNumber as String] as? Int,
              let owner = entry[kCGWindowOwnerName as String] as? String,
              let boundsDict = entry[kCGWindowBounds as String] as? [String: Any],
              let rect = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
        else { return nil }
        let title = entry[kCGWindowName as String] as? String ?? ""
        let layer = entry[kCGWindowLayer as String] as? Int ?? 0
        return WindowInfo(number: number, owner: owner, title: title, layer: layer, bounds: rect)
    }
}

func printWindows(ownerFilter: String?) {
    let windows = listWindows().filter { w in
        guard let f = ownerFilter, !f.isEmpty else { return true }
        return w.owner.localizedCaseInsensitiveContains(f)
    }
    for w in windows {
        let b = w.bounds
        print("\(w.number)\t\(Int(b.origin.x)),\(Int(b.origin.y)),\(Int(b.width)),\(Int(b.height))\tlayer=\(w.layer)\t\(w.owner)\t\(w.title)")
    }
}

/// Prints the window number of the best match, or exits non-zero.
/// Prefers the largest matching window, which skips shadow/helper windows.
func printWindowID(owner: String, title: String) {
    let matches = listWindows().filter { w in
        w.owner.localizedCaseInsensitiveContains(owner)
            && (title.isEmpty || w.title.localizedCaseInsensitiveContains(title))
    }
    guard let best = matches.max(by: { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height }) else {
        FileHandle.standardError.write("no window matching owner=\(owner) title=\(title)\n".data(using: .utf8)!)
        exit(1)
    }
    print(best.number)
}

// MARK: - Synthetic events

let eventSource = CGEventSource(stateID: .combinedSessionState)

func pause(_ seconds: Double) {
    Thread.sleep(forTimeInterval: seconds)
}

/// Posts a mouse event with an explicit click state. Without it synthetic
/// clicks arrive as `clickCount == 0`, which AppKit views routinely discard —
/// the drag then never starts.
func postMouse(_ type: CGEventType, at point: CGPoint, clickState: Int64) {
    guard let event = CGEvent(mouseEventSource: eventSource, mouseType: type,
                              mouseCursorPosition: point, mouseButton: .left) else { return }
    event.setIntegerValueField(.mouseEventClickState, value: clickState)
    event.post(tap: .cghidEventTap)
}

func moveMouse(to point: CGPoint) {
    postMouse(.mouseMoved, at: point, clickState: 0)
}

func click(at point: CGPoint) {
    moveMouse(to: point)
    pause(0.08)
    postMouse(.leftMouseDown, at: point, clickState: 1)
    pause(0.06)
    postMouse(.leftMouseUp, at: point, clickState: 1)
}

/// Drags in interpolated steps — a single jump is frequently ignored by
/// drawing canvases that track incremental mouse movement.
func drag(from start: CGPoint, to end: CGPoint, steps: Int = 30) {
    dragHold(from: start, to: end, steps: steps)
    postMouse(.leftMouseUp, at: end, clickState: 1)
}

/// Drags but keeps the button down, so the caller decides when to let go.
///
/// Split out for `drag-shot`: an area selection only exists while the mouse is
/// held, and `drag` always ends with mouseUp — by the time it returns there is
/// nothing left on screen to photograph.
func dragHold(from start: CGPoint, to end: CGPoint, steps: Int = 30) {
    moveMouse(to: start)
    pause(0.15)
    postMouse(.leftMouseDown, at: start, clickState: 1)
    pause(0.12)
    for i in 1...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let p = CGPoint(x: start.x + (end.x - start.x) * t,
                        y: start.y + (end.y - start.y) * t)
        postMouse(.leftMouseDragged, at: p, clickState: 1)
        pause(0.015)
    }
    pause(0.12)
}

// MARK: - Keyboard

/// Virtual keycodes are physical positions, so these stay correct on a German
/// layout as long as we avoid the Y/Z pair.
let keyCodes: [String: CGKeyCode] = [
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
    "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
    "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "9": 25, "7": 26, "8": 28, "0": 29,
    "o": 31, "u": 32, "i": 34, "p": 35, "return": 36, "l": 37, "j": 38, "k": 40,
    "n": 45, "m": 46,
    "tab": 48, "space": 49, "delete": 51, "escape": 53, "esc": 53,
    "left": 123, "right": 124, "down": 125, "up": 126,
]

func pressKey(combo: String) {
    var flags: CGEventFlags = []
    var keyName = ""
    for part in combo.lowercased().split(separator: "+").map(String.init) {
        switch part {
        case "cmd", "command": flags.insert(.maskCommand)
        case "shift": flags.insert(.maskShift)
        case "ctrl", "control": flags.insert(.maskControl)
        case "alt", "option": flags.insert(.maskAlternate)
        default: keyName = part
        }
    }
    guard let code = keyCodes[keyName] else {
        FileHandle.standardError.write("unknown key: \(keyName)\n".data(using: .utf8)!)
        exit(1)
    }
    let down = CGEvent(keyboardEventSource: eventSource, virtualKey: code, keyDown: true)
    down?.flags = flags
    down?.post(tap: .cghidEventTap)
    pause(0.05)
    let up = CGEvent(keyboardEventSource: eventSource, virtualKey: code, keyDown: false)
    up?.flags = flags
    up?.post(tap: .cghidEventTap)
}

// MARK: - Window capture

/// Captures a window by number, including its shadow, at backing resolution.
///
/// Shells out to `screencapture` because CGWindowListCreateImage was removed in
/// macOS 15. Staying inside this process still matters — it avoids a second
/// shell round-trip while a transient panel is on screen.
func captureWindow(number: Int, to output: String) -> Bool {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    task.arguments = ["-x", "-l\(number)", output]
    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        return false
    }
    guard task.terminationStatus == 0,
          FileManager.default.fileExists(atPath: output) else { return false }
    print("captured window \(number) -> \(output)")
    return true
}

/// Captures one whole display. Used where the subject is an overlay rather than
/// a window — a selection rectangle, the colour loupe, the measurement guides.
func captureDisplay(_ display: Int, to output: String) -> Bool {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    task.arguments = ["-x", "-D\(display)", output]
    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        return false
    }
    guard task.terminationStatus == 0,
          FileManager.default.fileExists(atPath: output) else { return false }
    print("captured display \(display) -> \(output)")
    return true
}

/// Finds a window belonging to `owner` whose height falls inside the given
/// range, preferring the topmost (highest layer) match.
func findWindow(owner: String, minHeight: CGFloat, maxHeight: CGFloat) -> WindowInfo? {
    listWindows()
        .filter { $0.owner.localizedCaseInsensitiveContains(owner) }
        .filter { $0.bounds.height >= minHeight && $0.bounds.height <= maxHeight }
        .max(by: { $0.layer < $1.layer })
}

/// Moves the pointer to a target in small increments, then immediately locates
/// and captures a transient panel. Doing this inside one process matters:
/// launching a separate capture process gives assistive features (dwell click)
/// enough time to dismiss the panel first.
func hoverShot(target: CGPoint, owner: String, minHeight: CGFloat, maxHeight: CGFloat, output: String) {
    let start = CGPoint(x: target.x - 60, y: target.y - 40)
    for i in 0...12 {
        let t = CGFloat(i) / 12
        moveMouse(to: CGPoint(x: start.x + (target.x - start.x) * t,
                              y: start.y + (target.y - start.y) * t))
        pause(0.03)
    }
    // Let the panel redraw with the value under the final position.
    pause(0.45)
    guard let window = findWindow(owner: owner, minHeight: minHeight, maxHeight: maxHeight) else {
        FileHandle.standardError.write("hover-shot: no matching window\n".data(using: .utf8)!)
        exit(1)
    }
    if !captureWindow(number: window.number, to: output) {
        FileHandle.standardError.write("hover-shot: capture failed\n".data(using: .utf8)!)
        exit(1)
    }
}

// MARK: - Cropping

/// Crops a screenshot given point coordinates. Screenshots come back at the
/// display's backing scale, so the rect is scaled to pixels first.
func crop(input: String, output: String, rect: CGRect) {
    guard let image = NSImage(contentsOfFile: input),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
        FileHandle.standardError.write("cannot read \(input)\n".data(using: .utf8)!)
        exit(1)
    }
    // Screen points -> image pixels
    let screenWidthPoints = NSScreen.screens.first?.frame.width ?? 1
    let scale = CGFloat(cgImage.width) / screenWidthPoints
    let pixelRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale,
                           width: rect.width * scale, height: rect.height * scale)
    guard let cropped = cgImage.cropping(to: pixelRect) else {
        FileHandle.standardError.write("crop rect out of bounds\n".data(using: .utf8)!)
        exit(1)
    }
    let rep = NSBitmapImageRep(cgImage: cropped)
    guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
    do {
        try png.write(to: URL(fileURLWithPath: output))
        print("cropped \(cropped.width)x\(cropped.height) -> \(output)")
    } catch {
        FileHandle.standardError.write("\(error.localizedDescription)\n".data(using: .utf8)!)
        exit(1)
    }
}

// MARK: - Main

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    print("usage: UIDriver.swift <list|id|move|click|drag|drag-shot|key|shot|hover-shot|screen-shot|crop> ...")
    exit(1)
}

func num(_ index: Int) -> CGFloat {
    guard index < args.count, let value = Double(args[index]) else {
        FileHandle.standardError.write("missing numeric argument at position \(index)\n".data(using: .utf8)!)
        exit(1)
    }
    return CGFloat(value)
}

switch command {
case "list":
    printWindows(ownerFilter: args.count > 1 ? args[1] : nil)

case "id":
    guard args.count > 1 else { exit(1) }
    printWindowID(owner: args[1], title: args.count > 2 ? args[2] : "")

case "move":
    moveMouse(to: CGPoint(x: num(1), y: num(2)))

case "click":
    click(at: CGPoint(x: num(1), y: num(2)))

case "drag":
    drag(from: CGPoint(x: num(1), y: num(2)), to: CGPoint(x: num(3), y: num(4)))

case "key":
    guard args.count > 1 else { exit(1) }
    pressKey(combo: args[1])

case "shot":
    // shot <owner> <out> [minHeight] [maxHeight]
    guard args.count > 2 else {
        FileHandle.standardError.write("usage: shot <owner> <out> [minH] [maxH]\n".data(using: .utf8)!)
        exit(1)
    }
    let minH = args.count > 3 ? num(3) : 0
    let maxH = args.count > 4 ? num(4) : .greatestFiniteMagnitude
    guard let window = findWindow(owner: args[1], minHeight: minH, maxHeight: maxH) else {
        FileHandle.standardError.write("shot: no matching window\n".data(using: .utf8)!)
        exit(1)
    }
    if !captureWindow(number: window.number, to: args[2]) { exit(1) }

case "hover-shot":
    // hover-shot <x> <y> <owner> <out> [minH] [maxH]
    guard args.count > 4 else {
        FileHandle.standardError.write("usage: hover-shot <x> <y> <owner> <out> [minH] [maxH]\n".data(using: .utf8)!)
        exit(1)
    }
    hoverShot(target: CGPoint(x: num(1), y: num(2)),
              owner: args[3],
              minHeight: args.count > 5 ? num(5) : 0,
              maxHeight: args.count > 6 ? num(6) : .greatestFiniteMagnitude,
              output: args[4])

case "drag-shot":
    // drag-shot <x1> <y1> <x2> <y2> <out> [display]
    //
    // Drags and photographs the screen *before* letting go. The area selection
    // overlay draws its rectangle and size readout only while the button is
    // down; `drag` returns after mouseUp, when there is nothing left to see.
    guard args.count > 5 else {
        FileHandle.standardError.write("usage: drag-shot <x1> <y1> <x2> <y2> <out> [display]\n".data(using: .utf8)!)
        exit(1)
    }
    let ziel = CGPoint(x: num(3), y: num(4))
    dragHold(from: CGPoint(x: num(1), y: num(2)), to: ziel)
    let display = args.count > 6 ? Int(args[6]) ?? 1 : 1
    let ok = captureDisplay(display, to: args[5])
    // Released whatever happened, so a failed capture does not leave the
    // pointer stuck holding a selection over the whole screen.
    postMouse(.leftMouseUp, at: ziel, clickState: 1)
    if !ok { exit(1) }

case "screen-shot":
    // screen-shot <out> [display] — the whole display, for overlay subjects.
    guard args.count > 1 else {
        FileHandle.standardError.write("usage: screen-shot <out> [display]\n".data(using: .utf8)!)
        exit(1)
    }
    if !captureDisplay(args.count > 2 ? Int(args[2]) ?? 1 : 1, to: args[1]) { exit(1) }

case "crop":
    guard args.count > 6 else {
        FileHandle.standardError.write("usage: crop <in> <out> <x> <y> <w> <h>\n".data(using: .utf8)!)
        exit(1)
    }
    crop(input: args[1], output: args[2],
         rect: CGRect(x: num(3), y: num(4), width: num(5), height: num(6)))

default:
    FileHandle.standardError.write("unknown command: \(command)\n".data(using: .utf8)!)
    exit(1)
}
