// InputTypeTests.swift
// Exercise text-field validation and formatting without constructing a UI.

import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class InputTypeTests: XCTestCase {
    func testStepMultipliersMatchComponentScales() {
        XCTAssertEqual(InputType.degrees.multiplier, 360)
        XCTAssertEqual(InputType.percentage.multiplier, 100)
        XCTAssertEqual(InputType.numerical.multiplier, 255)
        XCTAssertEqual(InputType.hex.multiplier, 1)
    }

    func testDegreeParsingAndWrapAround() throws {
        XCTAssertEqual(InputType.degrees.parse("90°"), 90)
        XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize("360°")), 0)
        XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize("720")), 0)
        XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize("-1°")), 359.0 / 360.0, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize("-360")), 0)
    }

    func testPercentagesClampToZeroAndOne() throws {
        XCTAssertEqual(try XCTUnwrap(InputType.percentage.normalize("25%")), 0.25)
        XCTAssertEqual(try XCTUnwrap(InputType.percentage.normalize("150%")), 1)
        XCTAssertEqual(try XCTUnwrap(InputType.percentage.normalize("-10%")), 0)
    }

    func testRGBNumbersClampAndScaleFromZeroTo255() throws {
        XCTAssertEqual(try XCTUnwrap(InputType.numerical.normalize("128")), 128.0 / 255.0, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(InputType.numerical.normalize("300")), 1)
        XCTAssertEqual(try XCTUnwrap(InputType.numerical.normalize("-5")), 0)
    }

    func testHexAllowsOptionalHashAndMixedCase() throws {
        XCTAssertEqual(InputType.hex.parse("#a1B2c3"), 0xA1B2C3)
        XCTAssertEqual(InputType.hex.parse("A1B2C3"), 0xA1B2C3)
        // Unlike other input types, HEX normalization returns the whole 24-bit number.
        XCTAssertEqual(try XCTUnwrap(InputType.hex.normalize("#A1B2C3")), CGFloat(0xA1B2C3))
        XCTAssertEqual(try XCTUnwrap(InputType.hex.normalize("000000")), 0)
        XCTAssertEqual(try XCTUnwrap(InputType.hex.normalize("FFFFFF")), CGFloat(0xFFFFFF))
    }

    func testHexRequiresExactlySixValidHexDigits() {
        for invalid in ["", "#FFF", "FFF", "#12345", "#1234567", "#GGGGGG", "#12 456", "0x123456"] {
            XCTAssertNil(InputType.hex.parse(invalid), "Unexpectedly accepted \(invalid)")
            XCTAssertNil(InputType.hex.normalize(invalid), "Unexpectedly accepted \(invalid)")
        }
    }

    func testNumericInputsRejectNonIntegersAndWhitespace() {
        for invalid in ["", "1.5", "+5", " 50 ", "hello", "50%%"] {
            XCTAssertNil(InputType.percentage.parse(invalid), "Unexpectedly accepted \(invalid)")
            XCTAssertNil(InputType.degrees.normalize(invalid), "Unexpectedly accepted \(invalid)")
        }
    }

    func testFormattingProducesExpectedUserFacingStrings() {
        XCTAssertEqual(InputType.degrees.format(0), "0°")
        XCTAssertEqual(InputType.degrees.format(0.5), "180°")
        // The formatter deliberately caps a complete turn at 359°.
        XCTAssertEqual(InputType.degrees.format(1), "359°")
        XCTAssertEqual(InputType.percentage.format(0.255), "26%")
        XCTAssertEqual(InputType.percentage.format(1), "100%")
        XCTAssertEqual(InputType.numerical.format(0.5), "128")
        XCTAssertEqual(InputType.numerical.format(1), "255")
        XCTAssertEqual(InputType.hex.format(CGFloat(0x00A0EF)), "#00A0EF")
    }
}
