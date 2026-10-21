import AppKit
import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class NativePickerInteractionTests: XCTestCase {
    func testTriangleCentroidSelectsExpectedSaturationAndBrightness() throws {
        try PickerTestSupport.requireMetalResources()
        let box = PickerColorBox(HSBAColor(hue: 0, saturation: 1, brightness: 1, alpha: 0.4))
        let coordinator = HSVTriangleCoordinator(color: box.binding, storeColor: { box.commits += 1 })
        let view = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        performTestPan(in: view, from: CGPoint(x: 100, y: 100), handle: coordinator.handleDrag)
        XCTAssertEqual(box.color.saturation, 0.5, accuracy: 1e-9)
        XCTAssertEqual(box.color.brightness, 2.0 / 3, accuracy: 1e-9)
        XCTAssertEqual(box.color.alpha, 0.4)
        XCTAssertEqual(box.commits, 1)
    }

    func testTriangleNearCornersSelectHueBlackAndWhite() throws {
        try PickerTestSupport.requireMetalResources()
        let samples: [(CGPoint, RGB)] = [
            (CGPoint(x: 200, y: 100), RGB(red: 1, green: 0, blue: 0)),
            (CGPoint(x: 50, y: 100 + 50 * sqrt(3)), RGB(red: 0, green: 0, blue: 0)),
            (CGPoint(x: 50, y: 100 - 50 * sqrt(3)), RGB(red: 1, green: 1, blue: 1))
        ]
        for (corner, expected) in samples {
            let box = PickerColorBox(HSBAColor(hue: 0, saturation: 0.3, brightness: 0.4, alpha: 0.5))
            let coordinator = HSVTriangleCoordinator(color: box.binding, storeColor: { box.commits += 1 })
            let view = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            // Stay just inside the edge: exact boundary hit-testing is sensitive to rounding.
            let point = CGPoint(x: 100 + (corner.x - 100) * 0.999999, y: 100 + (corner.y - 100) * 0.999999)
            performTestPan(in: view, from: point, handle: coordinator.handleDrag)
            XCTAssertEqual(box.color.rgb.red, expected.red, accuracy: 2e-6)
            XCTAssertEqual(box.color.rgb.green, expected.green, accuracy: 2e-6)
            XCTAssertEqual(box.color.rgb.blue, expected.blue, accuracy: 2e-6)
            XCTAssertEqual(box.color.alpha, 0.5)
            XCTAssertEqual(box.commits, 1)
        }
    }

    func testTriangleIndicatorRoundTripsThroughNativePickingAtDifferentRotations() throws {
        try PickerTestSupport.requireMetalResources()
        let box = PickerColorBox(HSBAColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.35))
        let coordinator = HSVTriangleCoordinator(color: box.binding, storeColor: { box.commits += 1 })
        let view = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        for hue in [CGFloat(0), 0.125, 0.3, 0.5, 0.875] {
            for saturation in [CGFloat(0.15), 0.55, 0.9] {
                for brightness in [CGFloat(0.2), 0.6, 0.95] {
                    coordinator.hue = hue
                    box.color = HSBAColor(hue: hue, saturation: 0, brightness: 0, alpha: 0.35)
                    let expected = HSBAColor(hue: hue, saturation: saturation, brightness: brightness)
                    let geometry = HueRingPickerGeometry(color: expected, viewSize: CGSize(width: 320, height: 320))
                    let offset = geometry.hsvTriangleIndicatorOffset
                    // AppKit's Y axis is the inverse of the SwiftUI indicator's Y axis.
                    let point = CGPoint(x: 100 + offset.width, y: 100 - offset.height)
                    performTestPan(in: view, from: point, handle: coordinator.handleDrag)
                    XCTAssertEqual(box.color.saturation, saturation, accuracy: 1e-9)
                    XCTAssertEqual(box.color.brightness, brightness, accuracy: 1e-9)
                    XCTAssertEqual(box.color.hue, hue)
                    XCTAssertEqual(box.color.alpha, 0.35)
                }
            }
        }
        XCTAssertEqual(box.commits, 45)
    }

    func testTriangleClampsOutsideDragAndIgnoresOutsideStart() throws {
        try PickerTestSupport.requireMetalResources()
        let initial = HSBAColor(hue: 0.2, saturation: 0.4, brightness: 0.6, alpha: 0.5)
        let box = PickerColorBox(initial)
        let coordinator = HSVTriangleCoordinator(color: box.binding, storeColor: { box.commits += 1 })
        let view = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        performTestPan(in: view, from: CGPoint(x: -500, y: -500), to: CGPoint(x: 100, y: 100), handle: coordinator.handleDrag)
        XCTAssertEqual(box.color, initial)
        XCTAssertEqual(box.commits, 0)

        for end in [CGPoint(x: -500, y: 1000), CGPoint(x: 1000, y: -500), CGPoint(x: 1000, y: 1000)] {
            performTestPan(in: view, from: CGPoint(x: 100, y: 100), to: end, handle: coordinator.handleDrag)
            XCTAssertTrue(box.color.saturation.isFinite && box.color.brightness.isFinite)
            XCTAssertTrue((0...1).contains(box.color.saturation))
            XCTAssertTrue((0...1).contains(box.color.brightness))
            XCTAssertEqual(box.color.hue, initial.hue)
            XCTAssertEqual(box.color.alpha, initial.alpha)
        }
        XCTAssertEqual(box.commits, 3)
    }

    func testSquarePickingUsesAppKitAxesAndClampsToBounds() throws {
        try PickerTestSupport.requireMetalResources()
        let samples: [(CGPoint, CGFloat, CGFloat)] = [
            (.zero, 0, 0), (CGPoint(x: 200, y: 200), 1, 1),
            (CGPoint(x: 100, y: 50), 0.5, 0.25), (CGPoint(x: -20, y: 300), 0, 1)
        ]
        for (point, saturation, brightness) in samples {
            let box = PickerColorBox(HSBAColor(hue: 0.4, saturation: 0.3, brightness: 0.7, alpha: 0.6))
            let coordinator = HSVSquareCoordinator(color: box.binding, storeColor: { box.commits += 1 })
            let view = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            performTestPan(in: view, from: point, handle: coordinator.handleDrag)
            XCTAssertEqual(box.color.saturation, saturation, accuracy: 1e-9)
            XCTAssertEqual(box.color.brightness, brightness, accuracy: 1e-9)
            XCTAssertEqual(box.color.hue, 0.4)
            XCTAssertEqual(box.color.alpha, 0.6)
            XCTAssertEqual(box.commits, 1)
        }
    }

    func testSpherePickingUsesExpectedCardinalHues() throws {
        try PickerTestSupport.requireMetalResources()
        let samples: [(CGPoint, CGFloat)] = [
            (CGPoint(x: 190, y: 100), 0), (CGPoint(x: 100, y: 190), 0.25),
            (CGPoint(x: 10, y: 100), 0.5), (CGPoint(x: 100, y: 10), 0.75)
        ]
        for (point, hue) in samples {
            let box = PickerColorBox(HSBAColor(hue: 0.2, saturation: 0.4, brightness: 0.7, alpha: 0.6))
            let coordinator = HueSphereCoordinator(getColor: { box.color }, setColor: { box.color = $0 }, storeColor: { box.commits += 1 })
            let view = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            performTestPan(in: view, from: point, handle: coordinator.handleDrag)
            XCTAssertEqual(box.color.hue, hue, accuracy: 1e-9)
            XCTAssertEqual(box.color.saturation, 0.9, accuracy: 1e-9)
            XCTAssertEqual(box.color.brightness, 0.7)
            XCTAssertEqual(box.color.alpha, 0.6)
            XCTAssertEqual(box.commits, 1)
        }
    }

    func testSphereClampsOutsideDragAndIgnoresOutsideStart() throws {
        try PickerTestSupport.requireMetalResources()
        let initial = HSBAColor(hue: 0.2, saturation: 0.4, brightness: 0.7, alpha: 0.6)
        let box = PickerColorBox(initial)
        let coordinator = HueSphereCoordinator(getColor: { box.color }, setColor: { box.color = $0 }, storeColor: { box.commits += 1 })
        let view = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        performTestPan(in: view, from: .zero, to: CGPoint(x: 100, y: 100), handle: coordinator.handleDrag)
        XCTAssertEqual(box.color, initial)
        XCTAssertEqual(box.commits, 0)
        performTestPan(in: view, from: CGPoint(x: 100, y: 100), to: CGPoint(x: 500, y: 100), handle: coordinator.handleDrag)
        XCTAssertEqual(box.color.hue, 0, accuracy: 1e-9)
        XCTAssertEqual(box.color.saturation, 1, accuracy: 1e-9)
        XCTAssertEqual(box.color.brightness, initial.brightness)
        XCTAssertEqual(box.color.alpha, initial.alpha)
        XCTAssertEqual(box.commits, 1)
    }
}
