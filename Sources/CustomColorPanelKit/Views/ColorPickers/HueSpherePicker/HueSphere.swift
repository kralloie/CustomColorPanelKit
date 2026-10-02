//
//  HSVSphere.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import MetalKit
import SwiftUI

/// A Metal-rendered sphere where the magnitude of each pixel coordinate represents the saturation.
///
/// Rendering is performed by ``HueSpherecOORDINATOR``.
///
/// When creating the view, an ``ImmediatePanGestureRecognizer`` is added to the ``MTKView`` to modify the hue and saturation components with the gesture.
struct HueSphere: NSViewRepresentable {
    /// A binding to the current color being modified.
    @Binding var color: HSBAColor
    /// Called after the gesture finishes to store the color to the history.
    var storeColor: () -> Void
    
    func makeCoordinator() -> HueSphereCoordinator {
        HueSphereCoordinator(color: $color, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> some NSView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(ImmediatePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
}

@MainActor final class HueSphereCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueSphereVertexShader"
    static let fragmentShader: String = "HueSphereFragmentShader"
    
    /// A binding to the current color being modified.
    @Binding var color: HSBAColor
    /// Called after the gesture finishes to store the color to the history.
    var storeColor: () -> Void
    /// The point where the dragging gesture started, `nil` if no gesture is being performed.
    private var draggingStart: CGPoint?
    
    var metalDevice: MTLDevice!
    private var metalCommandQueue: MTLCommandQueue!
    private var renderPipeline: MTLRenderPipelineState
    
    init(color: Binding<HSBAColor>, storeColor: @escaping () -> Void) {
        _color = color
        self.storeColor = storeColor
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hueSpherePipeline
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange _: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /// The action that handles the drag gesture inside the Hue Sphere.
    ///
    /// Modifies the color based on the position of the cursor when the gesture is recognized calculating the Hue and Saturation components
    /// based on the angle and magnitude of the cursor coordinates.
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let radius = min(view.bounds.width, view.bounds.height) * 0.5
        
        let loc = gesture.location(in: view)
        if gesture.state == .began { draggingStart = loc }
        
        var x = (loc.x - radius) / radius
        var y = (loc.y - radius) / radius
        
        if let draggingStart = draggingStart {
            let draggingStartPoint = CGPoint(
                x: (draggingStart.x - radius) / radius,
                y: (draggingStart.y - radius) / radius
            )
            let draggingStartPointLen = hypot(draggingStartPoint.x, draggingStartPoint.y)
            if draggingStartPointLen > 1.0 { return }
        }
        
        var c = color
        var len = hypot(x, y)
        if len > 1.0 { x /= len; y /= len; len = 1.0 }
        c.saturation = len
        
        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        c.hue = hue
        
        color = c
        
        if gesture.state == .ended { storeColor() }
    }
}
