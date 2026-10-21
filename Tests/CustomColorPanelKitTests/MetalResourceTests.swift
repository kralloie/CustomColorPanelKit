import MetalKit
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class MetalResourceTests: XCTestCase {
    func testEveryPickerPipelineLoadsFromPackageResources() throws { try PickerTestSupport.requireMetalResources() }

    func testDefaultMetalViewUsesSRGBAndManualDrawing() throws {
        guard MTLCreateSystemDefaultDevice() != nil else {
            throw XCTSkip("This test requires a Metal device.")
        }
        let context = try MetalContext()
        let delegate = NoOpMetalDelegate()
        let view = context.makeDefaultMTKView(delegate: delegate)
        let colorspace = try XCTUnwrap(view.colorspace)
        XCTAssertEqual(colorspace.name.map { $0 as String }, CGColorSpace.sRGB as String)
        XCTAssertEqual(view.colorPixelFormat, .bgra8Unorm)
        XCTAssertTrue(view.isPaused)
        XCTAssertTrue(view.enableSetNeedsDisplay)
    }
}

@MainActor
private final class NoOpMetalDelegate: NSObject, MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {}
}
