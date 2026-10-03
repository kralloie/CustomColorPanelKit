//
//  HSVTriangle.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

/// A Metal-rendered triangle with each corner representing one of the HSV components.
///
/// Rendering is performed by ``HSVTriangleCoordinator``.
///
/// When creating the view, an ``ImmediatePanGestureRecognizer`` is added to the ``MTKView`` to modify the HSV components with the gesture.
struct HSVTriangle: NSViewRepresentable {
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// Called after the gesture finishes to store the color to the history.
    var storeColor: () -> Void
    
    func makeCoordinator() -> HSVTriangleCoordinator {
        HSVTriangleCoordinator(color: $color, storeColor: storeColor)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        mtkView.addGestureRecognizer(ImmediatePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:))))
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if context.coordinator.hue != color.hue {
            context.coordinator.hue = color.hue
            nsView.setNeedsDisplay(nsView.bounds)
        }
    }
    
    /// Returns an overlay for the MTKView that indicates the saturation and brightness values with its position inside the HSV Triangle.
    ///
    /// - Parameters:
    ///   - brightness: The current brightness value of the color being edited.
    ///   - offset: The offset that places the indicator within the HSV Triangle, calculated in ``HueRingPickerGeometry``.
    ///   - color: The color used as fill for the indicator with the current HSV values.
    func positionIndicator(brightness: CGFloat, offset: CGSize, color: Color) -> some View {
        overlay {
            let indicatorSize: CGFloat = 10
            Circle()
                .fill(color)
                .stroke(brightness > 0.5 ? .black : .white, lineWidth: 1)
                .frame(width: indicatorSize)
                .offset(offset)
        }
    }
}

/// The coordinator responsible for rendering an ``HSVTriangle`` using MetalKit.
///
/// The coordinator serves as the ``MTKViewDelegate`` for its underlying ``MTKView``.
@MainActor final class HSVTriangleCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HSVTriangleVertexShader"
    static let fragmentShader: String = "HSVTriangleFragmentShader"
    
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// Called after the gesture finishes to store the color to the history.
    var storeColor: () -> Void
    /// The point where the most recent drag gesture began.
    var draggingStart: CGPoint?
    /// The last hue passed to the shader.
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
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /// Returns the signed area of a triangle defined by  three vertices.
    ///
    /// The result is positive when the vertices are ordered counterclockwise
    /// and negative when they are ordered clockwise.
    ///
    /// - Parameters:
    ///   - a: Vertex 0.
    ///   - b: Vertex 1.
    ///   - c: Vertex 2.
    private func triangleArea(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        return ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) * 0.5
    }
    
    /// Returns the barycentric coordinates of a point within the triangle.
    ///
    /// - Returns: A tuple with the weight of each vertex.
    ///
    /// - Parameters:
    ///   - point: A point within the square where the triangle is drawn.
    ///   - size: The size of the triangle.
    private func getBarycentricCoordinates(for point: CGPoint, size: CGFloat) -> (w0: CGFloat, w1: CGFloat, w2: CGFloat) {
        let angle = self.hue * 2 * .pi
        let vertices = getVerticesForTriangle(size: size, angle: angle)
        let abc = abs(triangleArea(vertices[0], vertices[1], vertices[2]))
        
        let w0 = triangleArea(point, vertices[1], vertices[2]) / abc
        let w1 = triangleArea(vertices[0], point, vertices[2]) / abc
        let w2 = triangleArea(vertices[0], vertices[1], point) / abc
        
        return (w0, w1, w2)
    }
    
    /// Returns the coordinates for the triangle vertices.
    ///
    /// - Returns: A `[CGPoint]` with each vertex coordinate.
    ///
    /// - Parameters:
    ///   - size: The size of the triangle.
    ///   - angle: The angle at which triangle is rotated.
    private func getVerticesForTriangle(size: CGFloat, angle: CGFloat) -> [CGPoint] {
        let offset: CGFloat = GeometryConstants.triangleVertexSpacing
        let radius = size * 0.5
        return [
            CGPoint(x: cos(angle) * radius + radius, y: sin(angle) * radius + radius),
            CGPoint(x: cos(angle + offset) * radius + radius, y: sin(angle + offset) * radius + radius),
            CGPoint(x: cos(angle + offset * 2) * radius + radius, y: sin(angle + offset * 2) * radius + radius)
        ]
    }
    
    /// Calculates and returns saturation and brightness based on the weight of the hue and saturation vertices.
    ///
    /// - Returns: A tuple with the brightness and saturation values.
    ///
    /// - Parameters:
    ///   - hueWeight: Weight of the hue vertex.
    ///   - saturationWeight: Weight of the saturation vertex.
    private func saturationAndBrightness(hueWeight w0: CGFloat, saturationWeight w2: CGFloat) -> (brightness: CGFloat, saturation: CGFloat) {
        let v = w0 + w2
        let s = v > 1e-5 ? w0 / v : 0
        return (v, s)
    }
    
    /// The action that handles the drag gesture inside the HSV Triangle.
    ///
    /// Modifies the color based on the position of the cursor when the gesture is recognized calculating
    /// the saturation and brightness components using barycentric coordinates.
    ///
    /// Drags outside that start outside the shape are ignored and the pointer is clamped when it leaves the shape.
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
            let (brightness, saturation) = saturationAndBrightness(hueWeight: w0, saturationWeight: w2)
            var c = color
            c.brightness = brightness
            c.saturation = saturation
            color = c
            
            if gesture.state == .ended { storeColor() }
            return
        }
        
        let angle = self.hue * 2 * .pi
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
        
        let (brightness, saturation) = saturationAndBrightness(hueWeight: w0, saturationWeight: w2)
        var c = color
        c.brightness = brightness
        c.saturation = saturation
        color = c
        
        if gesture.state == .ended { storeColor() }
    }
}
