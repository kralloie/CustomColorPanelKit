//
//  HSVSquare.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 09/06/2026.
//

import SwiftUI
import MetalKit

/// A Metal-rendered square where the X axis represents saturation and the Y axis represents brightness.
///
/// Rendering is performed by ``HSVSquareCoordinator``.
///
/// When creating the view, an ``ImmediatePanGestureRecognizer`` is added to the ``MTKView`` to modify the HSV components with the gesture.
struct HSVSquare: NSViewRepresentable {
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// Called after the gesture finishes to store the color to the history.
    var storeColor: () -> Void
    
    func makeCoordinator() -> HSVSquareCoordinator {
        HSVSquareCoordinator(color: $color, storeColor: storeColor)
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
    
    /// Returns an overlay for the MTKView that indicates the saturation and brightness values with its position inside the HSV Square.
    ///
    /// - Parameters:
    ///   - squareSize: The size of the square being drawn.
    ///   - color: The current color used as fill for the indicator.
    func positionIndicator(squareSize: CGFloat, color: HSBAColor) -> some View {
        overlay {
            Circle()
                .fill(Color(hue: color.hue, saturation: color.saturation, brightness: color.brightness))
                .stroke(color.brightness > 0.5 ? .black : .white, lineWidth: 1)
                .frame(width: 10)
                .position(x: squareSize * color.saturation, y: squareSize - squareSize * color.brightness)
        }
    }
}

/// The coordinator responsible for rendering an``HSVSquare`` using MetalKit.
///
/// The coordinator serves as the ``MTKViewDelegate`` for its underlying ``MTKView``.
@MainActor final class HSVSquareCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HSVSquareVertexShader"
    static let fragmentShader: String = "HSVSquareFragmentShader"
    
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// Called after the gesture finishes to store the color to the history.
    var storeColor: () -> Void
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
        self.renderPipeline = ctx.hsvSquarePipeline
        
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
        renderEncoder.setFragmentBytes(&hue, length: MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /// The action that handles the drag gesture inside the HSV Square.
    ///
    /// Modifies the color based on the position of the cursor when the gesture is recognized calculating
    /// the saturation and brightness components the X position for saturation and Y position for brightness.
    ///
    /// Drags outside that start outside the shape are ignored and the pointer is clamped when it leaves the shape.
    @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        
        let x = min(max(loc.x, 0), view.bounds.width)
        let y = min(max(loc.y, 0), view.bounds.height)
        
        var c = color
        c.brightness = y / view.bounds.height
        c.saturation = x / view.bounds.width
        color = c
        
        if gesture.state == .ended { storeColor() }
    }
}
