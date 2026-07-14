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
    var antialiasing: Bool
    var storeColor: (HSBAColor) -> Void
    
    func makeCoordinator() -> HueRingCoordinator {
        HueRingCoordinator(antialiasing: antialiasing, storeColor: { storeColor(color) }) { point in
            let angle = atan2(-point.y, point.x)
            let normalized = angle < 0 ? angle + 2 * .pi : angle
            color.hue = normalized / (2 * .pi)
        }
    }
    
    func makeNSView(context: Context) -> MTKView {
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
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
}

@MainActor final class HueRingCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueRingVertexShader"
    static let fragmentShader: String = "HueRingFragmentShader"
    
    var size: CGFloat = 0
    private var antialiasing: Bool
    private var draggingStart: CGPoint?
    private var storeColor: () -> Void
    private var updateIndicatorPosition: (CGPoint) -> Void
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        antialiasing: Bool,
        storeColor: @escaping () -> Void,
        updateIndicatorPosition: @escaping (CGPoint) -> Void
    ) {
        self.antialiasing = antialiasing
        self.storeColor = storeColor
        self.updateIndicatorPosition = updateIndicatorPosition
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hueRingPipeline
        
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
        var antialiasing = self.antialiasing ? Float(0) : Float(1)
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
        
        if let draggingStart = draggingStart {
            let draggingStartPoint = CGPoint(
                x: (draggingStart.x - radius) / radius,
                y: -(draggingStart.y - radius) / radius
            )
            let draggingStartPointLen = hypot(draggingStartPoint.x, draggingStartPoint.y)
            if draggingStartPointLen > 1 || draggingStartPointLen < 0.75 { return }
        }
        
        var point = CGPoint(
            x: (loc.x - radius) / radius,
            y: -(loc.y - radius) / radius
        )
        
        let len = hypot(point.x, point.y)
        if len > 1 || len < 0.75 { point.x /= len; point.y /= len }
        
        updateIndicatorPosition(point)
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let radius = size * 0.5
        let loc = gesture.location(in: view)
        let point = CGPoint(
            x: (loc.x - radius) / radius,
            y: -(loc.y - radius) / radius
        )
        let len = hypot(point.x, point.y)

        if len <= 1 && len > 0.75 {
            updateIndicatorPosition(point)
            if gesture.state == .ended { storeColor() }
        }
    }
}
