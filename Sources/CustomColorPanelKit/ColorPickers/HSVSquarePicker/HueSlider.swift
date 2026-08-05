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
    var storeColor: (HSBAColor) -> Void
    
    func makeCoordinator() -> HueSliderCoordinator {
        HueSliderCoordinator(color: color, storeColor: { storeColor(color) }) { hue in
            color.hue = hue
        }
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
        if context.coordinator.color.hue != color.hue {
            context.coordinator.color = color
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class HueSliderCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueSliderVertexShader"
    static let fragmentShader: String = "HueSliderFragmentShader"
    
    var color: HSBAColor
    var size: CGFloat = 0
    var draggingStart: CGPoint?
    private var storeColor: () -> Void
    var updateHue: (CGFloat) -> Void
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        color: HSBAColor,
        storeColor: @escaping () -> Void,
        updateHue: @escaping (CGFloat) -> Void
    ) {
        self.color = color
        self.storeColor = storeColor
        self.updateHue = updateHue
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hueSliderPipeline
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange _: CGSize) {
        size = min(view.bounds.width, view.bounds.height)
    }
    
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
        let y = min(max(gesture.location(in: view).y, 0), view.bounds.height)
        
        updateHue(y / view.bounds.height)
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let y = gesture.location(in: view).y
        
        updateHue(y / view.bounds.height)
    }
}
