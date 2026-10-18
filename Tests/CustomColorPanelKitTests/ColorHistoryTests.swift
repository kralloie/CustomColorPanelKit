// ColorHistoryTests.swift
// Verify the most-recently-used behavior and approximate RGBA deduplication.

import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class ColorHistoryTests: XCTestCase {
    private func makeColor(hex: UInt32, alpha: CGFloat = 1) -> HSBAColor {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: alpha)
        color.hex = hex
        return color
    }

    func testHistoryStartsEmptyAndSafeAccessReturnsNil() {
        let history = ColorHistory()
        XCTAssertTrue(history.colors.isEmpty)
        XCTAssertNil(history[safe: -1])
        XCTAssertNil(history[safe: 0])
        XCTAssertNil(history.isStored(makeColor(hex: 0x123456)))
    }

    func testNewColorsAreAddedNewestFirst() {
        let history = ColorHistory()
        let red = makeColor(hex: 0xFF0000)
        let green = makeColor(hex: 0x00FF00)
        history.add(red)
        history.add(green)
        XCTAssertEqual(history.colors.count, 2)
        XCTAssertEqual(history[safe: 0]?.hex, 0x00FF00)
        XCTAssertEqual(history[safe: 1]?.hex, 0xFF0000)
        XCTAssertNil(history[safe: 2])
    }

    func testReaddingOlderColorMovesItToTheFront() {
        let history = ColorHistory()
        let red = makeColor(hex: 0xFF0000)
        let green = makeColor(hex: 0x00FF00)
        let blue = makeColor(hex: 0x0000FF)
        history.add(red)
        history.add(green)
        history.add(blue)
        history.add(red)
        XCTAssertEqual(history.colors.map(\.hex), [0xFF0000, 0x0000FF, 0x00FF00])
    }

    func testIdenticalCurrentColorDoesNotCreateDuplicate() {
        let history = ColorHistory()
        let color = makeColor(hex: 0x123456)
        history.add(color)
        history.add(color)
        XCTAssertEqual(history.colors.count, 1)
    }

    func testVisuallyEquivalentColorsAreDeduplicated() {
        let history = ColorHistory()
        let blackA = HSBAColor(hue: 0, saturation: 1, brightness: 0)
        let blackB = HSBAColor(hue: 0.8, saturation: 0.2, brightness: 0)
        XCTAssertNotEqual(blackA, blackB)
        history.add(blackA)
        history.add(blackB)
        XCTAssertEqual(history.colors.count, 1)
    }

    func testDifferentAlphaValuesAreSeparateHistoryEntries() {
        let history = ColorHistory()
        history.add(makeColor(hex: 0x123456, alpha: 0.25))
        history.add(makeColor(hex: 0x123456, alpha: 0.75))
        XCTAssertEqual(history.colors.count, 2)
        XCTAssertEqual(history.colors[0].alpha, 0.75)
    }

    func testCapacityDropsOldestEntry() {
        let history = ColorHistory()
        let total = ColorHistory.capacity + 1
        for index in 0..<total {
            history.add(HSBAColor(
                hue: CGFloat(index) / CGFloat(total),
                saturation: 1,
                brightness: 1
            ))
        }
        XCTAssertEqual(history.colors.count, ColorHistory.capacity)
        XCTAssertEqual(history.colors.first?.hue, CGFloat(total - 1) / CGFloat(total))
        XCTAssertNil(history.isStored(HSBAColor(hue: 0, saturation: 1, brightness: 1)))
    }

    func testDeleteRemovesEntryAndMissingDeleteDoesNothing() {
        let history = ColorHistory()
        let red = makeColor(hex: 0xFF0000)
        let green = makeColor(hex: 0x00FF00)
        history.add(red)
        history.add(green)
        history.delete(red)
        history.delete(red)
        XCTAssertEqual(history.colors.map(\.hex), [0x00FF00])
        XCTAssertNil(history.isStored(red))
    }

    func testClearEmptiesHistoryAndAllowsNewAdditions() {
        let history = ColorHistory()
        history.add(makeColor(hex: 0xFF0000))
        history.add(makeColor(hex: 0x0000FF))
        history.clear()
        XCTAssertTrue(history.colors.isEmpty)
        XCTAssertNil(history[safe: 0])
        history.add(makeColor(hex: 0x00FF00))
        XCTAssertEqual(history.colors.count, 1)
    }
}
