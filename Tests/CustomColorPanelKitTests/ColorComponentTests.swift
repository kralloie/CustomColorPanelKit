// ColorComponentTests.swift
// These test the same writable key paths used by the sidebar controls.

import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class ColorComponentTests: XCTestCase {
    private let tolerance: CGFloat = 1e-9

    func testHexComponentKeyPathWritesBackIntoHSBAColor() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.35)
        color[keyPath: ColorComponent<UInt32>.hex.keyPath] = 0x12AB34
        XCTAssertEqual(color.hex, 0x12AB34)
        XCTAssertEqual(color.alpha, 0.35)
    }

    func testRGBRedComponentKeyPathOnlyChangesRedChannel() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.45)
        color.hex = 0x123456
        let before = color.rgb
        color[keyPath: ColorComponent<CGFloat>.red.keyPath] = 128.0 / 255.0
        XCTAssertEqual(color.rgb.red, 128.0 / 255.0, accuracy: tolerance)
        XCTAssertEqual(color.rgb.green, before.green, accuracy: tolerance)
        XCTAssertEqual(color.rgb.blue, before.blue, accuracy: tolerance)
        XCTAssertEqual(color.alpha, 0.45)
    }

    func testHSLLightnessComponentKeyPathWritesBack() {
        var color = HSBAColor(hue: 0.4, saturation: 0.6, brightness: 0.7, alpha: 0.3)
        let oldHue = color.hsl.hue
        color[keyPath: ColorComponent<CGFloat>.lightness.keyPath] = 0.3
        XCTAssertEqual(color.hsl.lightness, 0.3, accuracy: tolerance)
        XCTAssertEqual(color.hsl.hue, oldHue, accuracy: tolerance)
        XCTAssertEqual(color.alpha, 0.3)
    }

    func testCMYKKeyComponentKeyPathWritesBack() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.8)
        color.cmyk = CMYK(cyan: 0.2, magenta: 0.1, yellow: 0.4, key: 0.25)
        color[keyPath: ColorComponent<CGFloat>.black.keyPath] = 0.4
        XCTAssertEqual(color.cmyk.key, 0.4, accuracy: tolerance)
        XCTAssertEqual(color.alpha, 0.8)
    }

    func testAlphaComponentKeyPathWritesAlphaDirectly() {
        var color = HSBAColor(hue: 0.1, saturation: 0.5, brightness: 0.7)
        let before = color.hex
        color[keyPath: ColorComponent<CGFloat>.alpha.keyPath] = 0.25
        XCTAssertEqual(color.alpha, 0.25)
        XCTAssertEqual(color.hex, before)
    }

    func testUInt32ComponentNumericHandlesInvalidAndOutOfRangeInput() {
        XCTAssertEqual(UInt32(value: -10), 0)
        XCTAssertEqual(UInt32(value: 12.9), 12) // truncates toward zero
        XCTAssertEqual(UInt32(value: .nan), 0)
        XCTAssertEqual(UInt32(value: .infinity), 0)
        XCTAssertEqual(UInt32(value: CGFloat(UInt32.max) + 1000), UInt32.max)
    }
}
