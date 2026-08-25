// HotkeyBindingTests.swift
// MikaScreenSnapTests
//
// Encoding, decoding and display of hotkey bindings — the values that survive a restart.

import XCTest
import Carbon
@testable import MikaScreenSnap

final class HotkeyBindingTests: XCTestCase {

    func testBindingSurvivesAJSONRoundTrip() throws {
        let original = HotkeyBinding(keyCode: 0x14, modifiers: UInt32(cmdKey | shiftKey | controlKey))

        let data = try JSONEncoder().encode(["fullScreen": original])
        let decoded = try JSONDecoder().decode([String: HotkeyBinding].self, from: data)

        XCTAssertEqual(decoded["fullScreen"], original)
    }

    func testDefaultBindingsAreAllDistinct() {
        let bindings = HotkeyAction.allCases.map(\.defaultBinding)
        let unique = Set(bindings.map { "\($0.keyCode)-\($0.modifiers)" })

        XCTAssertEqual(unique.count, bindings.count, "two actions ship with the same shortcut")
    }

    func testEveryActionHasItsOwnHotkeyID() {
        let ids = Set(HotkeyAction.allCases.map(\.hotkeyID))
        XCTAssertEqual(ids.count, HotkeyAction.allCases.count, "a duplicate id would fire the wrong action")
    }

    func testDisplayStringShowsModifiersInAppleOrder() {
        let binding = HotkeyBinding(keyCode: 0x14, modifiers: UInt32(cmdKey | shiftKey | controlKey))
        XCTAssertEqual(binding.displayString, "\u{2303}\u{21E7}\u{2318}3")
    }

    func testDisplayStringFallsBackForUnknownKeyCodes() {
        let binding = HotkeyBinding(keyCode: 0xFF, modifiers: UInt32(cmdKey))
        XCTAssertEqual(binding.displayString, "\u{2318}Key255")
    }

    func testDefaultFullScreenBindingIsControlShiftCommandThree() {
        XCTAssertEqual(HotkeyAction.fullScreen.defaultBinding.displayString, "\u{2303}\u{21E7}\u{2318}3")
    }
}
