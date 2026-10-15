//
//  HueRing.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import SwiftUI
import MetalKit

/// A Metal-rendered hue ring color picker.
///
/// ``HueRing`` displays a hue ring using MetalKit.
/// Rendering is performed by ``HueRingCoordinator``.
struct HueRing: NSViewRepresentable {
    func makeCoordinator() -> HueRingCoordinator {
        HueRingCoordinator()
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalContext.shared.makeDefaultMTKView(delegate: context.coordinator)
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
    
    /// Returns an overlay for the MTKView that indicates the current hue value on the ``HueRing``.
    ///
    /// The overlay utilizes a rectangle whose width is the same as the ring thickness
    /// and it places an overlay on top of that with the custom ``HueRingIndicator`` shape as indicator.
    ///
    /// - Parameter geometry: The ``HueRingPickerGeometry`` object containing the calculated offsets and sizes.
    func positionIndicator(geometry: HueRingPickerGeometry) -> some View {
        overlay {
            let indicatorSize: CGFloat = 20
            Rectangle()
                .fill(.clear)
                .frame(
                    width: geometry.hueRingIndicatorSize.width,
                    height: geometry.hueRingIndicatorSize.height
                )
                .overlay(alignment: .trailing) {
                    HueRingIndicator(rectangleWidth: indicatorSize * 0.5, cornerRadius: 4)
                        .fill(.white)
                        .frame(width: indicatorSize, height: indicatorSize)
                        .shadow(radius: 1)
                }
                .rotationEffect(Angle(radians: -geometry.hueAngle))
                .offset(geometry.hueRingIndicatorOffset)
                .allowsHitTesting(false)
        }
    }
}

/// The coordinator responsible for rendering a ``HueRing`` using MetalKit.
///
/// The coordinator serves as the ``MTKViewDelegate`` for its underlying ``MTKView``.
@MainActor final class HueRingCoordinator: NSObject, MTKViewDelegate {
    static let vertexShader: String = "HueRingVertexShader"
    static let fragmentShader: String = "HueRingFragmentShader"
    
    private var metalCommandQueue: MTLCommandQueue!
    private var renderPipeline: MTLRenderPipelineState
    
    override init() {
        let ctx = MetalContext.shared
        self.metalCommandQueue = ctx.commandQueue
        self.renderPipeline = ctx.hueRingPipeline
        
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
}
