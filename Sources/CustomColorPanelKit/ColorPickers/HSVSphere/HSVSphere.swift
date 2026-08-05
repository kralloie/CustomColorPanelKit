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
    let antialiasing: Bool
    var storeColor: () -> Void
    
    func makeCoordinator() -> HSVSphereCoordinator {
        HSVSphereCoordinator(color: $color, antialiasing: antialiasing, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> some NSView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        mtkView.layer?.isOpaque = false
        mtkView.enableSetNeedsDisplay = true
        mtkView.device = context.coordinator.metalDevice
        mtkView.autoResizeDrawable = true
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
    private var antialiasing: Bool
    private var storeColor: () -> Void
    
    private var size: CGFloat = 0
    private var draggingStart: CGPoint?
    
    var metalDevice: MTLDevice!
    private var metalCommandQueue: MTLCommandQueue!
    private var renderPipeline: MTLRenderPipelineState
    
    init(color: Binding<HSBAColor>, antialiasing: Bool, storeColor: @escaping () -> Void) {
        _color = color
        self.storeColor = storeColor
        self.antialiasing = antialiasing
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hsvSpherePipeline
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange _: CGSize) {
        size = min(view.bounds.width, view.bounds.height)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        var antialiasing = self.antialiasing ? Float(1) : Float(0)
        renderEncoder.setFragmentBytes(&antialiasing, length: MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        if gesture.state == .began { draggingStart = loc }
        let radius = size * 0.5
        var x = (loc.x - radius) / radius
        var y = (loc.y - radius) / radius
        var len = hypot(x, y)
        
        if let draggingStart = draggingStart {
            let draggingStartPoint = CGPoint(
                x: (draggingStart.x - radius) / radius,
                y: (draggingStart.y - radius) / radius
            )
            let draggingStartPointLen = hypot(draggingStartPoint.x, draggingStartPoint.y)
            if draggingStartPointLen > 1.0 { return }
        }
        
        if len > 1.0 { x /= len; y /= len; len = 1.0 }
        color.saturation = len
        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        color.hue = hue
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let radius = size * 0.5
        let loc = gesture.location(in: view)
        var x = (loc.x - radius) / radius
        var y = (loc.y - radius) / radius
        let len = hypot(x, y)
        
        if len > 1.0 { return }
        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        color.saturation = len
        color.hue = hue
        storeColor()
    }
}
