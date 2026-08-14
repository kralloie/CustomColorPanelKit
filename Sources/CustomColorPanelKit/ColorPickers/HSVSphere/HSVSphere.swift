//
//  HSVSphere.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import MetalKit
import SwiftUI

struct HSVSphere: NSViewRepresentable {
    @Binding var color: HSBAColor
    var storeColor: () -> Void
    
    func makeCoordinator() -> HSVSphereCoordinator {
        HSVSphereCoordinator(color: $color, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> some NSView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        mtkView.addGestureRecognizer(NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
}

@MainActor final class HSVSphereCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HSVSphereVertexShader"
    static let fragmentShader: String = "HSVSphereFragmentShader"
    
    @Binding var color: HSBAColor
    private var storeColor: () -> Void
    
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
        self.renderPipeline = ctx.hsvSpherePipeline
        
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
        
        var len = hypot(x, y)
        if len > 1.0 { x /= len; y /= len; len = 1.0 }
        color.saturation = len
        
        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        color.hue = hue
        
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let radius = min(view.bounds.width, view.bounds.height) * 0.5
        let loc = gesture.location(in: view)
        var x = (loc.x - radius) / radius
        var y = (loc.y - radius) / radius
        
        let len = hypot(x, y)
        if len > 1.0 { return }
        color.saturation = len
        
        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        color.hue = hue
        
        storeColor()
    }
}
