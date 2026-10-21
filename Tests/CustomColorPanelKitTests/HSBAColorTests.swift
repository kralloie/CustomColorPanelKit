// HSBAColorTests.swift
// Correctness tests for the color model used by all three pickers.

import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class HSBAColorTests: XCTestCase {
    private let tolerance: CGFloat = 1e-9

    private func assertRGB(
        _ color: HSBAColor,
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        accuracy: CGFloat = 1e-9,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(color.rgb.red, red, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(color.rgb.green, green, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(color.rgb.blue, blue, accuracy: accuracy, file: file, line: line)
    }

    func testInitializerStoresComponentsAndDefaultsToOpaque() {
        let color = HSBAColor(hue: 0.2, saturation: 0.3, brightness: 0.4)
        XCTAssertEqual(color.hue, 0.2)
        XCTAssertEqual(color.saturation, 0.3)
        XCTAssertEqual(color.brightness, 0.4)
        XCTAssertEqual(color.alpha, 1)
    }

    func testHSVProducesExpectedPrimaryAndSecondaryRGBColors() {
        let samples: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0,       1, 0, 0), // red
            (1.0 / 6, 1, 1, 0), // yellow
            (1.0 / 3, 0, 1, 0), // green
            (0.5,     0, 1, 1), // cyan
            (2.0 / 3, 0, 0, 1), // blue
            (5.0 / 6, 1, 0, 1)  // magenta
        ]
        for (hue, red, green, blue) in samples {
            let color = HSBAColor(hue: hue, saturation: 1, brightness: 1)
            assertRGB(color, red: red, green: green, blue: blue)
        }
    }

    func testWhiteGrayAndBlackAreAchromatic() {
        assertRGB(HSBAColor(hue: 0.7, saturation: 0, brightness: 1), red: 1, green: 1, blue: 1)
        assertRGB(HSBAColor(hue: 0.7, saturation: 0, brightness: 0.4), red: 0.4, green: 0.4, blue: 0.4)
        assertRGB(HSBAColor(hue: 0.7, saturation: 1, brightness: 0), red: 0, green: 0, blue: 0)
    }

    func testHueWrapsWhenConvertedToRGB() {
        let wrapped = HSBAColor(hue: 0.75, saturation: 0.8, brightness: 0.9)
        let negative = HSBAColor(hue: -0.25, saturation: 0.8, brightness: 0.9)
        let greaterThanOne = HSBAColor(hue: 1.75, saturation: 0.8, brightness: 0.9)

        assertRGB(negative, red: wrapped.rgb.red, green: wrapped.rgb.green, blue: wrapped.rgb.blue)
        assertRGB(greaterThanOne, red: wrapped.rgb.red, green: wrapped.rgb.green, blue: wrapped.rgb.blue)
    }

    func testRGBSetterClampsValuesAndPreservesAlpha() {
        var color = HSBAColor(hue: 0.2, saturation: 0.4, brightness: 0.6, alpha: 0.37)
        color.rgb = RGB(red: -1, green: 0.4, blue: 2)

        assertRGB(color, red: 0, green: 0.4, blue: 1)
        XCTAssertEqual(color.alpha, 0.37)
    }

    func testRGBRoundTripsThroughHSVAvoidingHueComparisonForGrays() {
        let samples: [RGB] = [
            RGB(red: 0.1, green: 0.2, blue: 0.9),
            RGB(red: 0.8, green: 0.55, blue: 0.3),
            RGB(red: 0.25, green: 0.25, blue: 0.25),
            RGB(red: 0, green: 0, blue: 0),
            RGB(red: 1, green: 1, blue: 1)
        ]
        for rgb in samples {
            var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.6)
            color.rgb = rgb
            assertRGB(color, red: rgb.red, green: rgb.green, blue: rgb.blue)
            XCTAssertEqual(color.alpha, 0.6)
        }
    }

    func testHSLSetterAndGetterRoundTripRGB() {
        let samples = [
            HSBAColor(hue: 0.08, saturation: 0.6, brightness: 0.75),
            HSBAColor(hue: 0.43, saturation: 0.9, brightness: 0.4),
            HSBAColor(hue: 0.81, saturation: 0.25, brightness: 0.95),
            HSBAColor(hue: 0.5, saturation: 0, brightness: 0.35),
            HSBAColor(hue: 0.3, saturation: 1, brightness: 0)
        ]
        for original in samples {
            var restored = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.2)
            restored.hsl = original.hsl
            assertRGB(restored, red: original.rgb.red, green: original.rgb.green, blue: original.rgb.blue)
            XCTAssertEqual(restored.alpha, 0.2)
        }
    }

    func testHSLBoundaryCasesStayFinite() {
        var color = HSBAColor(hue: 0, saturation: 1, brightness: 1)
        color.hsl = HSL(hue: 0.6, saturation: 1, lightness: 0)
        assertRGB(color, red: 0, green: 0, blue: 0)
        XCTAssertTrue(color.saturation.isFinite)

        color.hsl = HSL(hue: 0.6, saturation: 1, lightness: 1)
        assertRGB(color, red: 1, green: 1, blue: 1)
        XCTAssertTrue(color.saturation.isFinite)
    }

    func testHexSetterIgnoresHighBitsAndDoesNotChangeAlpha() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.4)
        color.hex = 0xAA112233

        XCTAssertEqual(color.hex, 0x112233)
        XCTAssertEqual(color.hexString, "#112233")
        XCTAssertEqual(color.alpha, 0.4)
        assertRGB(color, red: 0x11 / 255.0, green: 0x22 / 255.0, blue: 0x33 / 255.0)
    }

    func testHexRoundsChannelsToEightBits() {
        let gray = HSBAColor(hue: 0.5, saturation: 0, brightness: 0.5)
        XCTAssertEqual(gray.hex, 0x808080)
        XCTAssertEqual(gray.hexString, "#808080")
    }

    func testCMYKSetterProducesExpectedRGBValues() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.65)
        color.cmyk = CMYK(cyan: 0.2, magenta: 0.4, yellow: 0.1, key: 0.25)

        assertRGB(color, red: 0.6, green: 0.45, blue: 0.675)
        XCTAssertEqual(color.cmyk.key, 0.25, accuracy: tolerance)
        XCTAssertEqual(color.alpha, 0.65)
    }

    func testCMYKRoundTripsRGBIncludingBlack() {
        let samples = [
            HSBAColor(hue: 0.2, saturation: 0.5, brightness: 0.8),
            HSBAColor(hue: 0.7, saturation: 0.8, brightness: 0.4),
            HSBAColor(hue: 0, saturation: 0, brightness: 0),
            HSBAColor(hue: 0, saturation: 0, brightness: 1)
        ]
        for original in samples {
            var restored = HSBAColor(hue: 0, saturation: 0, brightness: 1, alpha: 0.3)
            restored.cmyk = original.cmyk
            assertRGB(restored, red: original.rgb.red, green: original.rgb.green, blue: original.rgb.blue)
            XCTAssertEqual(restored.alpha, 0.3)
        }
    }

    func testCMYKFullKeyForcesBlackRegardlessOfOtherChannels() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 1)
        color.cmyk = CMYK(cyan: 0.2, magenta: 0.4, yellow: 0.6, key: 1)
        assertRGB(color, red: 0, green: 0, blue: 0)
        XCTAssertEqual(color.cmyk.key, 1)
        XCTAssertEqual(color.cmyk.cyan, 0)
        XCTAssertEqual(color.cmyk.magenta, 0)
        XCTAssertEqual(color.cmyk.yellow, 0)
    }

    func testCMYKRemembersKeyAfterAlphaChangeButClearsOnHSVChange() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0)
        color.cmyk = CMYK(cyan: 0.2, magenta: 0.4, yellow: 0.1, key: 0.25)
        XCTAssertEqual(color.cmyk.key, 0.25, accuracy: tolerance)

        color.alpha = 0.3
        XCTAssertEqual(color.cmyk.key, 0.25, accuracy: tolerance)

        color.hue += 0.1
        let rgb = color.rgb
        let derivedKey = 1 - max(rgb.red, rgb.green, rgb.blue)
        XCTAssertEqual(color.cmyk.key, derivedKey, accuracy: tolerance)
    }

    func testCMYKRemembersKeyWhenSameHSVValueIsReassigned() {
        var color = HSBAColor(hue: 0, saturation: 0, brightness: 0)
        color.cmyk = CMYK(cyan: 0.2, magenta: 0.4, yellow: 0.1, key: 0.25)
        let currentHue = color.hue
        color.hue = currentHue
        XCTAssertEqual(color.cmyk.key, 0.25, accuracy: tolerance)
    }

    func testEqualityAndHashIgnoreRememberedCMYKKey() {
        var withKey = HSBAColor(hue: 0, saturation: 0, brightness: 0)
        withKey.cmyk = CMYK(cyan: 0.1, magenta: 0.2, yellow: 0.3, key: 0.2)
        let withoutKey = HSBAColor(hue: withKey.hue, saturation: withKey.saturation, brightness: withKey.brightness, alpha: withKey.alpha)
        XCTAssertEqual(withKey, withoutKey)
        XCTAssertEqual(Set([withKey, withoutKey]).count, 1)
    }

    func testApproximateEqualityUsesDisplayedRGBAInsteadOfHSV() {
        let blackA = HSBAColor(hue: 0, saturation: 1, brightness: 0)
        let blackB = HSBAColor(hue: 0.8, saturation: 0.3, brightness: 0)
        XCTAssertNotEqual(blackA, blackB)
        XCTAssertTrue(blackA ≈≈ blackB)

        let translucentBlack = HSBAColor(hue: 0, saturation: 1, brightness: 0, alpha: 0.5)
        XCTAssertFalse(blackA ≈≈ translucentBlack)
    }

    func testApproximateEqualityAcceptsSmallChannelDifferences() {
        let a = HSBAColor(hue: 0, saturation: 0, brightness: 0.5)
        let b = HSBAColor(hue: 0, saturation: 0, brightness: 0.5005)
        let c = HSBAColor(hue: 0, saturation: 0, brightness: 0.51)
        XCTAssertTrue(a ≈≈ b)
        XCTAssertFalse(a ≈≈ c)
    }

    func testNSColorInitializerPreservesSRGBAndAlpha() {
        let original = NSColor(srgbRed: 0.2, green: 0.4, blue: 0.7, alpha: 0.6)
        let converted = HSBAColor(with: original)
        assertRGB(converted, red: 0.2, green: 0.4, blue: 0.7, accuracy: 1e-6)
        XCTAssertEqual(converted.alpha, 0.6, accuracy: 1e-6)
    }

    func testResolvedSwiftUIColorInitializerPreservesSRGBAndAlpha() {
        let original = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.7, opacity: 0.6)
        let converted = HSBAColor(with: original, in: EnvironmentValues())
        assertRGB(converted, red: 0.2, green: 0.4, blue: 0.7, accuracy: 1e-5)
        XCTAssertEqual(converted.alpha, 0.6, accuracy: 1e-5)
    }
}
