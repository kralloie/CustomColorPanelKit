//
//  OpacitySlider.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import SwiftUI
import MetalKit

struct OpacitySlider: NSViewRepresentable {
    @Binding var color: HSBAColor
    var width: CGFloat
    
    func makeCoordinator() -> OpacitySliderCoordinator {
        OpacitySliderCoordinator(color: color, width: width) { pos in
            color.alpha = 1.0 - pos / width
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
        if context.coordinator.width != width {
            context.coordinator.width = width
            context.coordinator.updateOpacity = { pos in
                color.alpha = 1.0 - pos / width
            }
        }
        
        if context.coordinator.color.saturation != color.saturation || context.coordinator.color.hue != color.hue {
            context.coordinator.color = color
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class OpacitySliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "OpacitySliderVertexShader"
    static let fragmentShader: String = "OpacitySliderFragmentShader"
    
    var color: HSBAColor
    var width: CGFloat
    var updateOpacity: (CGFloat) -> Void
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(color: HSBAColor, width: CGFloat, updateIndicatorPosition: @escaping (CGFloat) -> Void) {
        self.color = color
        self.width = width
        self.updateOpacity = updateIndicatorPosition
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.opacitySliderPipeline
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(renderPipeline)
        var hsb = SIMD3<Float>(Float(color.hue), Float(color.saturation), Float(color.brightness))
        renderEncoder.setVertexBytes(&hsb, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        var pos = gesture.location(in: view).x
        if pos > width { pos = width }
        if pos < 0 { pos = 0 }
        updateOpacity(pos)
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let pos = gesture.location(in: view).x
        updateOpacity(pos)
    }
}
