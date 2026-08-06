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
        OpacitySliderCoordinator(color: $color, width: width)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        mtkView.addGestureRecognizer(NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if context.coordinator.width != width {
            context.coordinator.width = width
        }
        
        if context.coordinator.color.saturation != color.saturation || context.coordinator.color.hue != color.hue {
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class OpacitySliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "OpacitySliderVertexShader"
    static let fragmentShader: String = "OpacitySliderFragmentShader"
    
    @Binding var color: HSBAColor
    var width: CGFloat
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    private var centerLock = false
    private let snapDistance: CGFloat = 6
    
    init(color: Binding<HSBAColor>, width: CGFloat) {
        _color = color
        self.width = width
        
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
        var rgb = SIMD3<Float>(Float(color.rgb.red), Float(color.rgb.green), Float(color.rgb.blue))
        renderEncoder.setFragmentBytes(&rgb, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        var pos = gesture.location(in: view).x
        pos = min(max(pos, 0), width)
        
        let center = width * 0.5
        
        if !centerLock && abs(pos - center) < snapDistance {
            centerLock = true
            color.alpha = 0.5
            return
        }
        
        if centerLock {
            if abs(pos - center) < snapDistance * 2 {
                color.alpha = 0.5
                return
            } else {
                centerLock = false
            }
        }

        color.alpha = 1 - (pos / width)
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let pos = gesture.location(in: view).x
        color.alpha = 1 - (pos / width)
    }
}
