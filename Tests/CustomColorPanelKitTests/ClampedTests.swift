// ClampedTests.swift
// Small tests for the generic helper used by normalization and color conversion.

import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class ClampedTests: XCTestCase {
    func testClampsIntegersToClosedRange() {
        XCTAssertEqual((-10).clamped(to: 0...100), 0)
        XCTAssertEqual(120.clamped(to: 0...100), 100)
        XCTAssertEqual(50.clamped(to: 0...100), 50)
    }

    func testClampsFractionalComponentsToUnitInterval() {
        let below: CGFloat = -0.25
        let inside: CGFloat = 0.4
        let above: CGFloat = 1.25
        XCTAssertEqual(below.clamped(to: 0...1), 0)
        XCTAssertEqual(inside.clamped(to: 0...1), 0.4)
        XCTAssertEqual(above.clamped(to: 0...1), 1)
    }
}
