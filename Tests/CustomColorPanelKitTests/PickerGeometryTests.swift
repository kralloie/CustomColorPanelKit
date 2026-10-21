import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class PickerGeometryTests: XCTestCase {
    func testTriangleIndicatorCornersUseSwiftUICoordinates() {
        // A 320-point ring frame produces a 200-point triangle frame (radius 100).
        let samples: [(HSBAColor, CGSize)] = [
            (HSBAColor(hue: 0, saturation: 1, brightness: 1), CGSize(width: 100, height: 0)),
            (HSBAColor(hue: 0, saturation: 0.7, brightness: 0), CGSize(width: -50, height: -50 * sqrt(3))),
            (HSBAColor(hue: 0, saturation: 0, brightness: 1), CGSize(width: -50, height: 50 * sqrt(3)))
        ]
        for (color, expected) in samples {
            let geometry = HueRingPickerGeometry(color: color, viewSize: CGSize(width: 320, height: 320))
            XCTAssertEqual(geometry.triangleSize, 200, accuracy: 1e-9)
            XCTAssertEqual(geometry.hsvTriangleIndicatorOffset.width, expected.width, accuracy: 1e-9)
            XCTAssertEqual(geometry.hsvTriangleIndicatorOffset.height, expected.height, accuracy: 1e-9)
        }
    }

    func testTriangleCentroidIndicatorStaysCenteredAtDifferentRotations() {
        for hue in [CGFloat(0), 0.125, 0.3, 0.5, 0.875] {
            let color = HSBAColor(hue: hue, saturation: 0.5, brightness: 2.0 / 3)
            let geometry = HueRingPickerGeometry(color: color, viewSize: CGSize(width: 320, height: 320))
            XCTAssertEqual(geometry.hsvTriangleIndicatorOffset.width, 0, accuracy: 1e-9)
            XCTAssertEqual(geometry.hsvTriangleIndicatorOffset.height, 0, accuracy: 1e-9)
        }
    }

    func testHueRingIndicatorUsesExpectedCardinalPositions() {
        let samples: [(CGFloat, CGSize)] = [
            (0, CGSize(width: 140, height: 0)),
            (0.25, CGSize(width: 0, height: -140)),
            (0.5, CGSize(width: -140, height: 0)),
            (0.75, CGSize(width: 0, height: 140))
        ]
        for (hue, expected) in samples {
            let color = HSBAColor(hue: hue, saturation: 1, brightness: 1)
            let geometry = HueRingPickerGeometry(color: color, viewSize: CGSize(width: 320, height: 320))
            XCTAssertEqual(geometry.hueRingIndicatorOffset.width, expected.width, accuracy: 1e-9)
            XCTAssertEqual(geometry.hueRingIndicatorOffset.height, expected.height, accuracy: 1e-9)
        }
    }
}
