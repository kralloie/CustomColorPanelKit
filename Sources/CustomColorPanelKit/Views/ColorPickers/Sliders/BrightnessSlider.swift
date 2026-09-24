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
    @Binding var isDragging: Bool
    var storeColor: () -> Void
    
    func makeCoordinator() -> BrightnessSliderCoordinator {
        BrightnessSliderCoordinator(color: $color, isDragging: $isDragging, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(ImmediatePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        
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

@MainActor final class BrightnessSliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "BrightnessSliderVertexShader"
    static let fragmentShader: String = "BrightnessSliderFragmentShader"
    
    @Binding var color: HSBAColor
    @Binding var isDragging: Bool
    var storeColor: () -> Void
    
    var hue: CGFloat = .nan
    var saturation: CGFloat = .nan
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(color: Binding<HSBAColor>, isDragging: Binding<Bool>, storeColor: @escaping () -> Void) {
        _color = color
        _isDragging = isDragging
        self.storeColor = storeColor
        
        self.hue = color.wrappedValue.hue
        self.saturation = color.wrappedValue.saturation
        
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
        var hueSaturation = SIMD2<Float>(Float(self.hue), Float(self.saturation))
        renderEncoder.setFragmentBytes(&hueSaturation, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view, view.bounds.height > 0 else { return }
        if gesture.state == .began { isDragging = true }
        let height = view.bounds.height
        
        let pos = min(max(gesture.location(in: view).y, 0), view.bounds.height)
        
        color.brightness = (pos / height)
        
        if gesture.state == .ended {
            isDragging = false
            storeColor()
        }
    }
}
