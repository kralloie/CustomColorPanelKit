//
//  HSVSquare.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

struct HSVSquare: NSViewRepresentable {
    @Binding var color: HSBAColor
    var storeColor: () -> Void
    
    func makeCoordinator() -> HSVSquareCoordinator {
        HSVSquareCoordinator(color: $color, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        mtkView.addGestureRecognizer(NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if context.coordinator.hue != color.hue {
            context.coordinator.hue = color.hue
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class HSVSquareCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HSVSquareVertexShader"
    static let fragmentShader: String = "HSVSquareFragmentShader"
    
    @Binding var color: HSBAColor
    private var storeColor: () -> Void
    
    var size: CGFloat = 0
    var draggingStart: CGPoint?
    var hue: CGFloat = .nan
    
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        color: Binding<HSBAColor>,
        storeColor: @escaping () -> Void,
    ) {
        _color = color
        self.storeColor = storeColor
        self.hue = color.wrappedValue.hue
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hsvSquarePipeline
        
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
        var hue = Float(color.hue)
        renderEncoder.setFragmentBytes(&hue, length: MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        
        let x = min(max(loc.x, 0), view.bounds.width)
        let y = min(max(loc.y, 0), view.bounds.height)
        color.brightness = y / view.bounds.height
        color.saturation = x / view.bounds.width
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        
        let x = min(max(loc.x, 0), view.bounds.width)
        let y = min(max(loc.y, 0), view.bounds.height)
        color.brightness = y / view.bounds.height
        color.saturation = x / view.bounds.width
        storeColor()
    }
}
