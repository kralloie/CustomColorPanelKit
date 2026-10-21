import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class AdditionalColorModelTests: XCTestCase {
    private let tolerance: CGFloat = 1e-9

    func testHSLKnownReferenceColors() {
        let samples: [(HSL, RGB)] = [
            (HSL(hue: 0, saturation: 1, lightness: 0.5), RGB(red: 1, green: 0, blue: 0)),
            (HSL(hue: 0.5, saturation: 1, lightness: 0.25), RGB(red: 0, green: 0.5, blue: 0.5)),
            (HSL(hue: 1.0 / 3, saturation: 1, lightness: 0.75), RGB(red: 0.5, green: 1, blue: 0.5)),
            (HSL(hue: 0.8, saturation: 0, lightness: 0.4), RGB(red: 0.4, green: 0.4, blue: 0.4))
        ]
        for (hsl, expected) in samples {
            var color = HSBAColor(hue: 0.2, saturation: 0.3, brightness: 0.4, alpha: 0.37)
            color.hsl = hsl
            assertRGB(color.rgb, equals: expected)
            XCTAssertEqual(color.alpha, 0.37)
        }
    }

    func testCMYKGetterPreservesNoncanonicalComponents() {
        let expected = CMYK(cyan: 0.2, magenta: 0.4, yellow: 0.1, key: 0.25)
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.6)
        color.cmyk = expected
        let actual = color.cmyk
        XCTAssertEqual(actual.cyan, expected.cyan, accuracy: tolerance)
        XCTAssertEqual(actual.magenta, expected.magenta, accuracy: tolerance)
        XCTAssertEqual(actual.yellow, expected.yellow, accuracy: tolerance)
        XCTAssertEqual(actual.key, expected.key, accuracy: tolerance)
        XCTAssertEqual(color.alpha, 0.6)
    }

    func testHSLSetterClampsOutOfRangeComponents() {
        let samples: [(HSL, RGB)] = [
            (HSL(hue: -1, saturation: 2, lightness: 0.5), RGB(red: 1, green: 0, blue: 0)),
            (HSL(hue: 2, saturation: -1, lightness: 0.25), RGB(red: 0.25, green: 0.25, blue: 0.25)),
            (HSL(hue: 0.4, saturation: 2, lightness: -1), RGB(red: 0, green: 0, blue: 0)),
            (HSL(hue: 0.4, saturation: 2, lightness: 2), RGB(red: 1, green: 1, blue: 1))
        ]
        for (hsl, expected) in samples {
            var color = HSBAColor(hue: 0, saturation: 0, brightness: 0.5, alpha: 0.3)
            color.hsl = hsl
            assertRGB(color.rgb, equals: expected)
            XCTAssertTrue(color.hue.isFinite && color.saturation.isFinite && color.brightness.isFinite)
            XCTAssertEqual(color.alpha, 0.3)
        }
    }

    func testCMYKSetterClampsOutOfRangeComponents() {
        let samples: [(CMYK, RGB)] = [
            (CMYK(cyan: -1, magenta: 2, yellow: 0.5, key: -1), RGB(red: 1, green: 0, blue: 0.5)),
            (CMYK(cyan: -1, magenta: 2, yellow: 0.5, key: 2), RGB(red: 0, green: 0, blue: 0))
        ]
        for (cmyk, expected) in samples {
            var color = HSBAColor(hue: 0.2, saturation: 0.3, brightness: 0.4, alpha: 0.7)
            color.cmyk = cmyk
            assertRGB(color.rgb, equals: expected)
            XCTAssertTrue(color.hue.isFinite && color.saturation.isFinite && color.brightness.isFinite)
            XCTAssertEqual(color.alpha, 0.7)
        }
    }

    func testOtherColorEditsClearRememberedCMYKKey() {
        let edits: [(String, (inout HSBAColor) -> Void)] = [
            ("saturation", { $0.saturation = 0.8 }),
            ("brightness", { $0.brightness = 0.9 }),
            ("RGB", { $0.rgb = RGB(red: 0.2, green: 0.3, blue: 0.4) }),
            ("HEX", { $0.hex = 0x123456 })
        ]
        for (name, edit) in edits {
            var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.6)
            color.cmyk = CMYK(cyan: 0.2, magenta: 0.4, yellow: 0.1, key: 0.25)
            edit(&color)
            XCTAssertEqual(color.cmyk.key, 1 - color.brightness, accuracy: tolerance, name)
            XCTAssertEqual(color.alpha, 0.6, name)
        }
    }

    func testHexRoundTripAcrossRGBGrid() {
        let channels: [UInt32] = [0, 1, 127, 128, 254, 255]
        for red in channels {
            for green in channels {
                for blue in channels {
                    let expected = (red << 16) | (green << 8) | blue
                    var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.35)
                    color.hex = expected
                    XCTAssertEqual(color.hex, expected)
                    XCTAssertEqual(InputType.hex.parse(color.hexString), Int(expected))
                    XCTAssertEqual(color.alpha, 0.35)
                }
            }
        }
    }

    func testApproximateEqualityAtChannelAndAlphaToleranceBoundaries() {
        let epsilon: CGFloat = 1.0 / 512
        let differences: [(CGFloat, Bool)] = [(epsilon / 2, true), (epsilon, false), (epsilon * 2, false)]
        let base = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.5)

        for (difference, expected) in differences {
            let colors = [
                RGB(red: difference, green: 0, blue: 0),
                RGB(red: 0, green: difference, blue: 0),
                RGB(red: 0, green: 0, blue: difference)
            ]
            for rgb in colors {
                var other = base
                other.rgb = rgb
                XCTAssertEqual(base ≈≈ other, expected)
                XCTAssertEqual(other ≈≈ base, expected)
            }
            var other = base
            other.alpha += difference
            XCTAssertEqual(base ≈≈ other, expected)
            XCTAssertEqual(other ≈≈ base, expected)
        }
    }

    private func assertRGB(_ actual: RGB, equals expected: RGB, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.red, expected.red, accuracy: tolerance, file: file, line: line)
        XCTAssertEqual(actual.green, expected.green, accuracy: tolerance, file: file, line: line)
        XCTAssertEqual(actual.blue, expected.blue, accuracy: tolerance, file: file, line: line)
    }
}
