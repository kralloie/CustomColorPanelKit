//
//  MetalContext.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 08/06/2026.
//

import MetalKit

@MainActor final class MetalContext {
    @MainActor static let shared = try! MetalContext()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let hueRingPipeline: MTLRenderPipelineState
    let hsbTrianglePipeline: MTLRenderPipelineState
    let opacitySliderPipeline: MTLRenderPipelineState
    let colorExamplePipeline: MTLRenderPipelineState
    
    private init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
             fatalError("No Metal device available on this machine")
         }
         guard let queue = device.makeCommandQueue() else {
             fatalError("Failed to create a Metal command queue")
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
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            return try device.makeRenderPipelineState(descriptor: descriptor)
        }
        
        hueRingPipeline = try makePipeline(vertex: HueRingCoordinator.vertexShader, fragment: HueRingCoordinator.fragmentShader)
        hsbTrianglePipeline = try makePipeline(vertex: HSBTriangleCoordinator.vertexShader, fragment: HSBTriangleCoordinator.fragmentShader)
        opacitySliderPipeline = try makePipeline(vertex: OpacitySliderCoordinator.vertexShader, fragment: OpacitySliderCoordinator.fragmentShader)
        colorExamplePipeline = try makePipeline(vertex: ColorExampleCoordinator.vertexShader, fragment: ColorExampleCoordinator.fragmentShader)
    }
}
