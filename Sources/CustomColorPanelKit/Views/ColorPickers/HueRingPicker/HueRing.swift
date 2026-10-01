//
//  HueRing.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import SwiftUI
import MetalKit

struct HueRing: NSViewRepresentable {
    let color: HSBAColor
    
    func makeCoordinator() -> HueRingCoordinator {
        HueRingCoordinator(color: color)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
}

@MainActor final class HueRingCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueRingVertexShader"
    static let fragmentShader: String = "HueRingFragmentShader"
    
    let color: HSBAColor
    
    private var draggingStart: CGPoint?
    
    var metalDevice: MTLDevice!
    private var metalCommandQueue: MTLCommandQueue!
    private var renderPipeline: MTLRenderPipelineState
    
    init(color: HSBAColor) {
        self.color = color
        
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
}
