//
//  BrightnessSlider.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import SwiftUI
import MetalKit

struct BrightnessSlider: NSViewRepresentable {
    @Binding var color: HSBAColor
    var width: CGFloat
    var storeColor: () -> Void
    
    func makeCoordinator() -> BrightnessSliderCoordinator {
        BrightnessSliderCoordinator(color: $color, width: width, storeColor: storeColor)
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
        }
        
        if context.coordinator.color.saturation != color.saturation || context.coordinator.color.hue != color.hue {
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class BrightnessSliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "BrightnessSliderVertexShader"
    static let fragmentShader: String = "BrightnessSliderFragmentShader"
    
    @Binding var color: HSBAColor
    var width: CGFloat
    var storeColor: () -> Void
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    private var centerLock = false
    private let snapDistance: CGFloat = 6
    
    init(color: Binding<HSBAColor>, width: CGFloat, storeColor: @escaping () -> Void) {
        _color = color
        self.width = width
        self.storeColor = storeColor
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
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
        var hueSaturation = SIMD2<Float>(Float(color.hue), Float(color.saturation))
        renderEncoder.setFragmentBytes(&hueSaturation, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
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
            color.brightness = 0.5
            return
        }
        
        if centerLock {
            if abs(pos - center) < snapDistance * 2 {
                color.brightness = 0.5
                return
            } else {
                centerLock = false
            }
        }

        color.brightness = 1 - (pos / width)
        
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let pos = gesture.location(in: view).x
        color.brightness = 1 - (pos / width)
        storeColor()
    }
}
