//
//  HueSlider.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

struct HueSlider: NSViewRepresentable {
    var color: HSBAColor
    
    func makeCoordinator() -> HueSliderCoordinator {
        HueSliderCoordinator(color: color)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
}

@MainActor final class HueSliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueSliderVertexShader"
    static let fragmentShader: String = "HueSliderFragmentShader"
    
    private var color: HSBAColor
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        color: HSBAColor,
    ) {
        self.color = color
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hueSliderPipeline
        
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
}
