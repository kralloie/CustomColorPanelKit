import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class AdditionalInputTests: XCTestCase {
    func testNumericInputRejectsIntegerOverflow() {
        for inputType in [InputType.degrees, .percentage, .numerical] {
            for text in [String(repeating: "9", count: 1_000), "-" + String(repeating: "9", count: 1_000)] {
                XCTAssertNil(inputType.parse(text))
                XCTAssertNil(inputType.normalize(text))
            }
        }
    }

    func testDegreeNormalizationHandlesIntegerExtremes() throws {
        XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize(String(Int.min))), 352.0 / 360, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize(String(Int.max))), 7.0 / 360, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(InputType.percentage.normalize(String(Int.min))), 0)
        XCTAssertEqual(try XCTUnwrap(InputType.percentage.normalize(String(Int.max))), 1)
        XCTAssertEqual(try XCTUnwrap(InputType.numerical.normalize(String(Int.min))), 0)
        XCTAssertEqual(try XCTUnwrap(InputType.numerical.normalize(String(Int.max))), 1)
    }

    func testFormattingAndParsingRespectDisplayedPrecision() throws {
        let values: [CGFloat] = [0, 0.001, 0.125, 0.255, 0.5, 0.731, 0.999, 1]
        for inputType in [InputType.percentage, .numerical] {
            for value in values {
                let restored = try XCTUnwrap(inputType.normalize(inputType.format(value)))
                XCTAssertEqual(restored, value, accuracy: 0.5 / CGFloat(inputType.multiplier) + 1e-12)
            }
        }
        for degrees in [0, 1, 90, 180, 270, 359] {
            let value = CGFloat(degrees) / 360
            XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize(InputType.degrees.format(value))), value, accuracy: 1e-12)
        }
        XCTAssertEqual(try XCTUnwrap(InputType.degrees.normalize(InputType.degrees.format(1))), 359.0 / 360, accuracy: 1e-12)
    }
}
