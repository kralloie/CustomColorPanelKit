//
//  ColorExample.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI
import MetalKit

/// A Metal-rendered color rectangle whose inferior triangle is affected by the alpha component but the superior triangle is not.
///
/// At 0% opacity it will only render the superior triangle, while the inferior triangle will be transparent.
///
/// Rendering is performed by ``ColorExampleCoordinator``.
struct ColorExample: NSViewRepresentable {
    /// The current color.
    var color: HSBAColor
    
    func makeCoordinator() -> ColorExampleCoordinator {
        ColorExampleCoordinator(color: color)
    }
    
    func makeNSView(context: Context) -> MTKView {
        return MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if color != context.coordinator.color {
            context.coordinator.color = color
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

/// The coordinator responsible for rendering a``ColorExample`` using MetalKit.
///
/// The coordinator serves as the ``MTKViewDelegate`` for its underlying ``MTKView``.
@MainActor final class ColorExampleCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "ColorExampleVertexShader"
    static let fragmentShader: String = "ColorExampleFragmentShader"
    
    /// The last color passed to the shader.
    var color: HSBAColor
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(color: HSBAColor) {
        self.color = color
        
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
