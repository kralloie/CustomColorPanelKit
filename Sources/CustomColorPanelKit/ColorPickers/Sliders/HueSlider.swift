//
//  HueSlider.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

struct HueSlider: NSViewRepresentable {
    @Binding var color: HSBAColor
    @Binding var isDragging: Bool
    var storeColor: () -> Void
    
    func makeCoordinator() -> HueSliderCoordinator {
        HueSliderCoordinator(color: $color, isDragging: $isDragging, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        mtkView.addGestureRecognizer(ImmediatePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
}

@MainActor final class HueSliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueSliderVertexShader"
    static let fragmentShader: String = "HueSliderFragmentShader"
    
    @Binding var color: HSBAColor
    @Binding var isDragging: Bool
    private var storeColor: () -> Void
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        color: Binding<HSBAColor>,
        isDragging: Binding<Bool>,
        storeColor: @escaping () -> Void,
    ) {
        _color = color
        _isDragging = isDragging
        self.storeColor = storeColor
        
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
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        if gesture.state == .began { isDragging = true }
        
        let y = min(max(gesture.location(in: view).y, 0), view.bounds.height)
        color.hue = y / view.bounds.height
        
        if gesture.state == .ended {
            isDragging = false
            storeColor()
        }
    }
}
