//
//  HSVSquare.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

struct HSVSquare: NSViewRepresentable {
    @Binding var color: HSBAColor
    var storeColor: () -> Void
    
    func makeCoordinator() -> HSVSquareCoordinator {
        HSVSquareCoordinator(color: color, storeColor: { storeColor() }) { brightness, saturation in
            color.brightness = brightness
            color.saturation = saturation
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
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if context.coordinator.color.hue != color.hue {
            context.coordinator.color = color
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class HSVSquareCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HSVSquareVertexShader"
    static let fragmentShader: String = "HSVSquareFragmentShader"
    
    var color: HSBAColor
    var size: CGFloat = 0
    var draggingStart: CGPoint?
    private var storeColor: () -> Void
    var updateIndicatorPosition: (CGFloat, CGFloat) -> Void
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        color: HSBAColor,
        storeColor: @escaping () -> Void,
        updateIndicatorPosition: @escaping (CGFloat, CGFloat) -> Void
    ) {
        self.color = color
        self.storeColor = storeColor
        self.updateIndicatorPosition = updateIndicatorPosition
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hsvSquarePipeline
        
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
        var hue = Float(color.hue)
        renderEncoder.setFragmentBytes(&hue, length: MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        
        let x = min(max(loc.x, 0), view.bounds.width)
        let y = min(max(loc.y, 0), view.bounds.height)
        updateIndicatorPosition(y / view.bounds.height, x / view.bounds.width)
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        
        let x = min(max(loc.x, 0), view.bounds.width)
        let y = min(max(loc.y, 0), view.bounds.height)
        updateIndicatorPosition(y / view.bounds.height, x / view.bounds.width)
        storeColor()
    }
}
