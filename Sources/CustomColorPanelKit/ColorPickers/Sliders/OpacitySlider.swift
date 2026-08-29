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
    
    func makeCoordinator() -> OpacitySliderCoordinator {
        OpacitySliderCoordinator(color: $color)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        mtkView.addGestureRecognizer(NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:))))
        
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
    
    @Binding var color: HSBAColor
    
    var hue: CGFloat = .nan
    var saturation: CGFloat = .nan
    var brightness: CGFloat = .nan
    var rgbComponents: SIMD3<Float> = .init(repeating: 0)
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    private var centerLock = false
    private let snapDistance: CGFloat = 6
    
    init(color: Binding<HSBAColor>) {
        _color = color
        
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
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view, view.bounds.width > 0 else { return }
        let width = view.bounds.width
        
        var pos = min(max(gesture.location(in: view).x, 0), view.bounds.width)
        
        let center = width * 0.5
        
        if gesture.state == .began { centerLock = false }
        
        if !centerLock && abs(pos - center) < snapDistance {
            centerLock = true
            color.alpha = 0.5
        } else if centerLock && abs(pos - center) < snapDistance * 2 {
            color.alpha = 0.5
        } else {
            centerLock = false
            color.alpha = (pos / width)
        }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view, view.bounds.width > 0 else { return }
        let width = view.bounds.width
        var pos = min(max(gesture.location(in: view).x, 0), view.bounds.width)
        color.alpha = (pos / width)
    }
}
