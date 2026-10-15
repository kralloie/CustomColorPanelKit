//
//  BrightnessSlider.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import SwiftUI
import MetalKit

/// A Metal-rendered slider that displays the current color with all possible brightness values from 0% to 100% brightness.
///
/// Rendering is performed by ``BrightnessSliderCoordinator``.
struct BrightnessSlider: NSViewRepresentable {
    /// The current color being edited.
    var color: HSBAColor
    
    func makeCoordinator() -> BrightnessSliderCoordinator {
        BrightnessSliderCoordinator(color: color)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if context.coordinator.saturation != color.saturation || context.coordinator.hue != color.hue {
            context.coordinator.hue = color.hue
            context.coordinator.saturation = color.saturation
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

/// The coordinator responsible for rendering a ``BrightnessSlider`` using MetalKit.
///
/// The coordinator serves as the ``MTKViewDelegate`` for its underlying ``MTKView``.
@MainActor final class BrightnessSliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "BrightnessSliderVertexShader"
    static let fragmentShader: String = "BrightnessSliderFragmentShader"
    
    /// The current color being edited.
    var color: HSBAColor
    
    /// The last hue passed to the shader.
    var hue: CGFloat = .nan
    /// The last saturation passed to the shader.
    var saturation: CGFloat = .nan
    
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(color: HSBAColor) {
        self.color = color
        
        self.hue = color.hue
        self.saturation = color.saturation
        
        let ctx = MetalContext.shared
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.brightnessSliderPipeline
        
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
        var hueSaturation = SIMD2<Float>(Float(self.hue), Float(self.saturation))
        renderEncoder.setFragmentBytes(&hueSaturation, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
