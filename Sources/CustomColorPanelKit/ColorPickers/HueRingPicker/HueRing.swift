//
//  HueRing.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import SwiftUI
import MetalKit

struct HueRing: NSViewRepresentable {
    @Binding var color: HSBAColor
    var storeColor: () -> Void
    
    func makeCoordinator() -> HueRingCoordinator {
        HueRingCoordinator(color: $color, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(ImmediatePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
}

@MainActor final class HueRingCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueRingVertexShader"
    static let fragmentShader: String = "HueRingFragmentShader"
    
    @Binding var color: HSBAColor
    private var storeColor: () -> Void
    
    private var draggingStart: CGPoint?
    
    var metalDevice: MTLDevice!
    private var metalCommandQueue: MTLCommandQueue!
    private var renderPipeline: MTLRenderPipelineState
    
    init(
        color: Binding<HSBAColor>,
        storeColor: @escaping () -> Void,
    ) {
        _color = color
        self.storeColor = storeColor
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hueRingPipeline
        
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
            if draggingStartPointLen > 1.0 || draggingStartPointLen < 0.75 { return }
        }
        
        let len = hypot(x, y)
        if len > 1.0 || len < 0.75 { x /= len; y /= len }
        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        color.hue = hue
        
        if gesture.state == .ended { storeColor() }
    }
}
