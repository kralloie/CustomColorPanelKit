//
//  MetalContext.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 08/06/2026.
//

import MetalKit

/// Manages the Metal resources shared by the views.
@MainActor final class MetalContext {
    /// The shared Metal rendering context.
    @MainActor static let shared = {
        do { return try MetalContext() }
        catch { fatalError("CustomColorPanelKit: failed to initialize Metal - \(error)") }
    }()
    
    /// Creates an `MTKView` configured for Metal rendering within the color picker.
    ///
    /// The view is configured for manual drawing and transparent rendering,
    /// and uses the context's Metal device.
    func makeDefaultMTKView(delegate: MTKViewDelegate) -> MTKView {
        let view = MTKView()
        view.delegate = delegate
        view.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        view.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        view.layer?.isOpaque = false
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.device = device
        view.autoResizeDrawable = true
        return view
    }
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let hueRingPipeline: MTLRenderPipelineState
    let hsvTrianglePipeline: MTLRenderPipelineState
    let opacitySliderPipeline: MTLRenderPipelineState
    let colorExamplePipeline: MTLRenderPipelineState
    let hsvSquarePipeline: MTLRenderPipelineState
    let hueSliderPipeline: MTLRenderPipelineState
    let hueSpherePipeline: MTLRenderPipelineState
    let brightnessSliderPipeline: MTLRenderPipelineState
    
    private init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw NSError(domain: "MetalSetup", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Metal device available on this machine"])
        }
        guard let queue = device.makeCommandQueue() else {
            throw NSError(domain: "MetalSetup", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create a Metal command queue"])
        }
        self.device = device
        self.commandQueue = queue

        let library = try device.makeDefaultLibrary(bundle: .module)
        
        func makePipeline(vertex: String, fragment: String) throws -> MTLRenderPipelineState {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: vertex)
            descriptor.fragmentFunction = library.makeFunction(name: fragment)
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].alphaBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            return try device.makeRenderPipelineState(descriptor: descriptor)
        }
        
        hueRingPipeline = try makePipeline(vertex: HueRingCoordinator.vertexShader, fragment: HueRingCoordinator.fragmentShader)
        hsvTrianglePipeline = try makePipeline(vertex: HSVTriangleCoordinator.vertexShader, fragment: HSVTriangleCoordinator.fragmentShader)
        opacitySliderPipeline = try makePipeline(vertex: OpacitySliderCoordinator.vertexShader, fragment: OpacitySliderCoordinator.fragmentShader)
        colorExamplePipeline = try makePipeline(vertex: ColorExampleCoordinator.vertexShader, fragment: ColorExampleCoordinator.fragmentShader)
        hsvSquarePipeline = try makePipeline(vertex: HSVSquareCoordinator.vertexShader, fragment: HSVSquareCoordinator.fragmentShader)
        hueSliderPipeline = try makePipeline(vertex: HueSliderCoordinator.vertexShader, fragment: HueSliderCoordinator.fragmentShader)
        hueSpherePipeline = try makePipeline(vertex: HueSphereCoordinator.vertexShader, fragment: HueSphereCoordinator.fragmentShader)
        brightnessSliderPipeline = try makePipeline(vertex: BrightnessSliderCoordinator.vertexShader, fragment: BrightnessSliderCoordinator.fragmentShader)
    }
}
