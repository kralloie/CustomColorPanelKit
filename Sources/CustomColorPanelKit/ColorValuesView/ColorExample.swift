//
//  ColorExample.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI
import MetalKit

struct ColorExample: NSViewRepresentable {
    var color: HSBAColor
    var size: CGFloat
    
    func makeCoordinator() -> ColorExampleCoordinator {
        ColorExampleCoordinator(color: color, size: size)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        mtkView.layer?.isOpaque = false
        mtkView.enableSetNeedsDisplay = true
        mtkView.device = context.coordinator.metalDevice
        mtkView.autoResizeDrawable = true
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if color != context.coordinator.color {
            context.coordinator.color = color
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class ColorExampleCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "ColorExampleVertexShader"
    static let fragmentShader: String = "ColorExampleFragmentShader"
    
    var color: HSBAColor
    var size: CGFloat
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(color: HSBAColor, size: CGFloat) {
        self.color = color
        self.size = size
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.colorExamplePipeline
        
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
        var hsba = SIMD4<Float>(Float(color.hue), Float(color.saturation), Float(color.brightness), Float(color.alpha))
        renderEncoder.setFragmentBytes(&hsba, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
