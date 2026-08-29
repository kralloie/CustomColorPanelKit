//
//  HSBTriangle.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

struct HSVTriangle: NSViewRepresentable {
    @Binding var color: HSBAColor
    var hueRotation: Bool
    var storeColor: () -> Void
    
    func makeCoordinator() -> HSVTriangleCoordinator {
        HSVTriangleCoordinator(color: $color, hueRotation: hueRotation, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        mtkView.addGestureRecognizer(NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if context.coordinator.hue != color.hue || context.coordinator.hueRotation != hueRotation {
            context.coordinator.hueRotation = hueRotation
            context.coordinator.hue = color.hue
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
}

@MainActor final class HSVTriangleCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HSVTriangleVertexShader"
    static let fragmentShader: String = "HSVTriangleFragmentShader"
    
    @Binding var color: HSBAColor
    var hueRotation: Bool
    private var storeColor: () -> Void
    
    var draggingStart: CGPoint?
    var hue: CGFloat = .nan
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipeline: MTLRenderPipelineState
    
    init(
        color: Binding<HSBAColor>,
        hueRotation: Bool,
        storeColor: @escaping () -> Void,
    ) {
        _color = color
        self.hueRotation = hueRotation
        self.storeColor = storeColor
        self.hue = color.wrappedValue.hue
        
        let ctx = MetalContext.shared
        self.metalDevice = ctx.device
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hsvTrianglePipeline
        
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
        var hue = Float(self.hue)
        renderEncoder.setVertexBytes(&hue, length: MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&hueRotation, length: MemoryLayout<Bool>.stride, index: 1)
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func triangleArea(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        return ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) * 0.5
    }
    
    private func getBarycentricCoordinates(for p: CGPoint, size: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        let angle = hueRotation ? self.hue * 2 * .pi : .pi * 0.5
        let vertices = getVerticesForTriangle(size: size, angle: angle)
        let abc = abs(triangleArea(vertices[0], vertices[1], vertices[2]))
        
        let w0 = triangleArea(p, vertices[1], vertices[2]) / abc
        let w1 = triangleArea(vertices[0], p, vertices[2]) / abc
        let w2 = triangleArea(vertices[0], vertices[1], p) / abc
        
        return (w0, w1, w2)
    }
    
    private func getVerticesForTriangle(size: CGFloat, angle: CGFloat) -> [CGPoint] {
        let offset: CGFloat = GeometryConstants.triangleVertexSpacing
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
        let size = min(view.bounds.width, view.bounds.height)
        
        let loc = gesture.location(in: view)
        if gesture.state == .began { draggingStart = loc }
        
        if let draggingStart = draggingStart {
            let (w0, w1, w2) = getBarycentricCoordinates(for: draggingStart, size: size)
            if w0 < 0 || w1 < 0 || w2 < 0 { return }
        }
        
        var (w0, w1, w2) = getBarycentricCoordinates(for: loc, size: size)
        if w0 >= 0 && w1 >= 0 && w2 >= 0 {
            let (brightness, saturation) = saturationAndBrightness(fromColorWeight: w0, whiteWeight: w2)
            var c = color
            c.brightness = brightness
            c.saturation = saturation
            color = c
            
            if gesture.state == .ended { storeColor() }
            return
        }
        
        let angle = hueRotation ? self.hue * 2 * .pi : .pi * 0.5
        let triangle = getVerticesForTriangle(size: size, angle: angle)
        
        let c0 = max(0, w0)
        let c1 = max(0, w1)
        let c2 = max(0, w2)
        let sum = c0 + c1 + c2
        
        (w0, w1, w2) = getBarycentricCoordinates(for:
            CGPoint(
                x: (c0 * triangle[0].x + c1 * triangle[1].x + c2 * triangle[2].x) / sum,
                y: (c0 * triangle[0].y + c1 * triangle[1].y + c2 * triangle[2].y) / sum
            ),
            size: size
        )
        
        let (brightness, saturation) = saturationAndBrightness(fromColorWeight: w0, whiteWeight: w2)
        var c = color
        c.brightness = brightness
        c.saturation = saturation
        color = c
        
        if gesture.state == .ended { storeColor() }
    }
    
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let view = gesture.view else { return }
        let size = min(view.bounds.width, view.bounds.height)
        let loc = gesture.location(in: view)
        let (w0, w1, w2) = getBarycentricCoordinates(for: loc, size: size)
        if w0 >= 0 && w1 >= 0 && w2 >= 0 {
            let (brightness, saturation) = saturationAndBrightness(fromColorWeight: w0, whiteWeight: w2)
            var c = color
            c.brightness = brightness
            c.saturation = saturation
            color = c
            
            storeColor()
        }
    }
}
