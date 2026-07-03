//
//  HSBTriangle.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

struct HSBTriangle: NSViewRepresentable {
    @Binding var color: HSBAColor
    var size: CGFloat
    var antialiasing: Bool
    var hueRotation: Bool
    var storeColor: (HSBAColor) -> Void
    
    func makeCoordinator() -> HSBTriangleCoordinator {
        HSBTriangleCoordinator(color: color, size: size, antialiasing: antialiasing, hueRotation: hueRotation, storeColor: { storeColor(color) }) { brightness, saturation in
            color.brightness = brightness
            color.saturation = saturation
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
        if context.coordinator.size != size {
            context.coordinator.size = size
        }
        
        if context.coordinator.color.hue != color.hue {
            context.coordinator.color = color
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class HSBTriangleCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HSBTriangleVertexShader"
    static let fragmentShader: String = "HSBTriangleFragmentShader"
    
    var color: HSBAColor
    var size: CGFloat
    var antialiasing: Bool
    var hueRotation: Bool
    var draggingStart: CGPoint?
    private var storeColor: () -> Void
    var updateIndicatorPosition: (CGFloat, CGFloat) -> Void
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        color: HSBAColor,
        size: CGFloat,
        antialiasing: Bool,
        hueRotation: Bool,
        storeColor: @escaping () -> Void,
        updateIndicatorPosition: @escaping (CGFloat, CGFloat) -> Void
    ) {
        self.color = color
        self.size = size
        self.antialiasing = antialiasing
        self.hueRotation = hueRotation
        self.storeColor = storeColor
        self.updateIndicatorPosition = updateIndicatorPosition
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hsbTrianglePipeline
        
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
        var hue = Float(color.hue)
        var antialiasing = self.antialiasing ? Float(0) : Float(1)
        renderEncoder.setVertexBytes(&hue, length: MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&hueRotation, length: MemoryLayout<Bool>.stride, index: 1)
        renderEncoder.setFragmentBytes(&antialiasing, length: MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func triangleArea(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        return ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) * 0.5
    }
    
    private func getBarycentricCoordinates(for p: CGPoint) -> (CGFloat, CGFloat, CGFloat) {
        let angle = hueRotation ? color.hue * 2 * .pi : .pi * 0.5
        let vertices = getVerticesForTriangle(size: self.size, angle: angle)
        let abc = abs(triangleArea(vertices[0], vertices[1], vertices[2]))
        
        let w0 = triangleArea(p, vertices[1], vertices[2]) / abc
        let w1 = triangleArea(vertices[0], p, vertices[2]) / abc
        let w2 = triangleArea(vertices[0], vertices[1], p) / abc
        
        return (w0, w1, w2)
    }
    
    private func getVerticesForTriangle(size: CGFloat, angle: CGFloat) -> [CGPoint] {
        let offset: CGFloat = 2 * .pi / 3
        let radius = size * 0.5
        return [
            CGPoint(x: cos(angle) * radius + radius, y: sin(angle) * radius + radius),
            CGPoint(x: cos(angle + offset) * radius + radius, y: sin(angle + offset) * radius + radius),
            CGPoint(x: cos(angle + offset * 2) * radius + radius, y: sin(angle + offset * 2) * radius + radius)
        ]
    }
    
    private func saturationAndBrightness(fromColorWeight w0: CGFloat, whiteWeight w2: CGFloat) -> (brightness: CGFloat, saturation: CGFloat) {
        let v = w0 + w2
        let s = v > 1e-5 ? w0 / v : 0
        return (v, s)
    }
    
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        
        if gesture.state == .began { draggingStart = loc }
        
        if let draggingStart = draggingStart {
            let (w0, w1, w2) = getBarycentricCoordinates(for: draggingStart)
            if w0 < 0 || w1 < 0 || w2 < 0 { return }
        }
        
        var (w0, w1, w2) = getBarycentricCoordinates(for: loc)
        if w0 >= 0 && w1 >= 0 && w2 >= 0 {
            let (brightness, saturation) = saturationAndBrightness(fromColorWeight: w0, whiteWeight: w2)
            updateIndicatorPosition(brightness, saturation)
            if gesture.state == .ended { storeColor() }
            return
        }
        
        let angle = hueRotation ? color.hue * 2 * .pi : .pi * 0.5
        let triangle = getVerticesForTriangle(size: self.size, angle: angle)
        
        let c0 = max(0, w0)
        let c1 = max(0, w1)
        let c2 = max(0, w2)
        let sum = c0 + c1 + c2
        
        (w0, w1, w2) = getBarycentricCoordinates(for:
            CGPoint(
                x: (c0 * triangle[0].x + c1 * triangle[1].x + c2 * triangle[2].x) / sum,
                y: (c0 * triangle[0].y + c1 * triangle[1].y + c2 * triangle[2].y) / sum
            )
        )
        
        let (brightness, saturation) = saturationAndBrightness(fromColorWeight: w0, whiteWeight: w2)
        updateIndicatorPosition(brightness, saturation)
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        let (w0, w1, w2) = getBarycentricCoordinates(for: loc)
        if w0 >= 0 && w1 >= 0 && w2 >= 0 {
            let (brightness, saturation) = saturationAndBrightness(fromColorWeight: w0, whiteWeight: w2)
            updateIndicatorPosition(brightness, saturation)
            storeColor()
        }
    }
}
