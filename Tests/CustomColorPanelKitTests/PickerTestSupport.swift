import AppKit
import MetalKit
import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
enum PickerTestSupport {
    static func requireMetalResources() throws {
        guard MTLCreateSystemDefaultDevice() != nil else {
            throw XCTSkip("This test requires a Metal device.")
        }
        _ = try MetalContext()
    }
}

@MainActor
final class PickerColorBox {
    var color: HSBAColor
    var commits = 0
    init(_ color: HSBAColor) { self.color = color }
    var binding: Binding<HSBAColor> {
        Binding(get: { self.color }, set: { self.color = $0 })
    }
}

@MainActor
final class LocatedPanGesture: NSPanGestureRecognizer {
    var point: CGPoint = .zero
    private var simulatedState: NSGestureRecognizer.State = .possible

    override var state: NSGestureRecognizer.State {
        get { simulatedState }
        set { simulatedState = newValue }
    }

    override func location(in view: NSView?) -> NSPoint { point }
}

@MainActor
func performTestPan(in view: NSView, from start: CGPoint, to end: CGPoint? = nil, handle: (NSPanGestureRecognizer) -> Void) {
    let gesture = LocatedPanGesture(target: nil, action: nil)
    view.addGestureRecognizer(gesture)
    defer { view.removeGestureRecognizer(gesture) }
    gesture.point = start
    gesture.state = .began
    handle(gesture)
    if let end {
        gesture.point = end
        gesture.state = .changed
        handle(gesture)
    }
    gesture.state = .ended
    handle(gesture)
}
