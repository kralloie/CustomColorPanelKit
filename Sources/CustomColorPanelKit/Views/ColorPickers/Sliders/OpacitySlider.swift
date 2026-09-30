//
//  OpacitySlider.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import SwiftUI
import MetalKit

struct OpacitySlider: NSViewRepresentable {
    var color: HSBAColor
    
    func makeCoordinator() -> OpacitySliderCoordinator {
        OpacitySliderCoordinator(color: color)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if context.coordinator.hue != color.hue || context.coordinator.saturation != color.saturation || context.coordinator.brightness != color.brightness {
            context.coordinator.hue = color.hue
            context.coordinator.saturation = color.saturation
            context.coordinator.brightness = color.brightness
            context.coordinator.rgbComponents = SIMD3<Float>(Float(color.rgb.red), Float(color.rgb.green), Float(color.rgb.blue))
            
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class OpacitySliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "OpacitySliderVertexShader"
    static let fragmentShader: String = "OpacitySliderFragmentShader"
    
    var color: HSBAColor
    
    var hue: CGFloat = .nan
    var saturation: CGFloat = .nan
    var brightness: CGFloat = .nan
    var rgbComponents: SIMD3<Float> = .init(repeating: 0)
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(color: HSBAColor) {
        self.color = color
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
        renderEncoder.setFragmentBytes(&rgbComponents, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
