//
//  BaseShader.swift
//  ShaderKit
//
//  Created by Alisdair Mills on 03/12/2019.
//  Copyright © 2019 amills. All rights reserved.
//

import Foundation
import Metal
import MetalKit

protocol ARDepthShader {
    func useDepthTexture(_ texture: MTLTexture)
}

open class BaseShader: NSObject {
    
    private static var positionVertex: [Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]
    private var texCoordVertex: [Float] = [0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]
    private var pipelines: [MTLRenderPipelineState] = []
    private var computes: [MTLComputePipelineState] = []
    private var aspectScale: CGFloat = 1.0
    
    var uniformBufferAddress: UnsafeMutableRawPointer?
    var positionBuffer: MTLBuffer?
    var coordBuffer: MTLBuffer?
    
    open func invertAspect() -> Bool { return false }
    open func flipAspect() -> Bool { return false }
    open func needsSourceAspect() -> Bool { return false }
    open func obseleteForCurrentFrame() -> Bool { return false }
    open func generate(device: MTLDevice) {}
    open func addUniforms(pass: Int, encoder: MTLRenderCommandEncoder, device: MTLDevice, size: CGSize) {}
    open func pipelineForPassThrough(pass: Int) -> MTLRenderPipelineState? {
        if pass < pipelines.count { return pipelines[pass] }
        return nil
    }
    open func computeForPassThrough(pass: Int) -> MTLComputePipelineState? {
        if pass < computes.count { return computes[pass] }
        return nil
    }
    open func postRender(pass: Int, encoder: MTLRenderCommandEncoder, device: MTLDevice, drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer) {}
    open func setComputeValues(encoder: MTLComputeCommandEncoder, device: MTLDevice, drawable: CAMetalDrawable) {}
    open func coordBuffer(pass: Int) -> MTLBuffer? {
        return coordBuffer
    }
    
    open func updateCoords(device: MTLDevice, resolution: CGSize, viewport: CGSize) {
        let resolutionRatio = resolution.width / resolution.height
        let viewportRatio = viewport.height / viewport.width
        let width = resolutionRatio / viewportRatio
        let start = (1.0 - width) / 2.0
        let end = start + width
        texCoordVertex = [0.0, end.float, 0.0, start.float, 1.0, end.float, 1.0, start.float]
        let coordDataCount = texCoordVertex.count * MemoryLayout<Float>.size
        coordBuffer = device.makeBuffer(bytes: texCoordVertex, length: coordDataCount, options: [])
        coordBuffer?.label = "\(theClassName)CoordBuffer"
        aspectScale = (viewport.width / viewport.height) / (resolution.height / resolution.width)
        if flipAspect() { aspectScale = 1.0 }
        AnonPhoto.viewportSize = viewport
        AnonPhoto.resolution = resolution
    }
    
    public func render(pass: Int, encoder: MTLRenderCommandEncoder, device: MTLDevice, texY: CVMetalTexture, texCbCr: CVMetalTexture, mirrored: Bool, size: CGSize) -> Bool {
        if let pipeline = pipelineForPassThrough(pass: pass) {
            encoder.pushDebugGroup("\(theClassName)Draw")
            encoder.setFrontFacing(.counterClockwise)
            encoder.setCullMode(.none)
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(coordBuffer(pass: pass), offset: 0, index: 1)
            var vertexUniforms = VertexUniforms()
            if mirrored { vertexUniforms.mirrored = -1.0 }
            else { vertexUniforms.mirrored = 1.0 }
            vertexUniforms.aspectScale = aspectScale.float
            encoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 3)
            encoder.setFragmentTexture(CVMetalTextureGetTexture(texY), index: 1)
            encoder.setFragmentTexture(CVMetalTextureGetTexture(texCbCr), index: 2)
            addUniforms(pass: pass, encoder: encoder, device: device, size: size)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            encoder.popDebugGroup()
            if pipelines.count > pass + 1 { return true }
        }
        return false
    }
    
    public func hasComputes() -> Bool {
        return computes.count > 0
    }
    
    public func hasRenders() -> Bool {
        return pipelines.count > 0
    }
    
    public func compute(pass: Int, encoder: MTLComputeCommandEncoder, device: MTLDevice, drawable: CAMetalDrawable) -> Bool {
        if let compute = computeForPassThrough(pass: pass) {
            encoder.setComputePipelineState(compute)
            setComputeValues(encoder: encoder, device: device, drawable: drawable)
            
            let w = Int(drawable.texture.width)
            let h = Int(drawable.texture.height)
            let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
            let numGroups = MTLSize(width: w / threadGroupSize.width + 1, height: h / threadGroupSize.height + 1, depth: 1)
            encoder.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadGroupSize)
            if computes.count > pass + 1 { return true }
        }
        return false
    }
    
    public func computeFrom(device: MTLDevice, name: String) {
        if let defaultLibrary = device.makeDefaultLibrary(), let program = defaultLibrary.makeFunction(name: name) {
            if let compute = try? device.makeComputePipelineState(function: program) {
                computes.append(compute)
            }
        }
    }
    
    public func generateFrom(device: MTLDevice, vertex: String, fragment: String) {
        if let defaultLibrary = device.makeDefaultLibrary(), let vertexFunc = defaultLibrary.makeFunction(name: vertex), let fragmentFunc = defaultLibrary.makeFunction(name: fragment) {
            
            let positionDataCount = BaseShader.positionVertex.count * MemoryLayout<Float>.size
            positionBuffer = device.makeBuffer(bytes: BaseShader.positionVertex, length: positionDataCount, options: [])
            positionBuffer?.label = "\(theClassName)PositionBuffer"
            
            let coordDataCount = texCoordVertex.count * MemoryLayout<Float>.size
            coordBuffer = device.makeBuffer(bytes: texCoordVertex, length: coordDataCount, options: [])
            coordBuffer?.label = "\(theClassName)CoordBuffer"
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.label = theClassName
            descriptor.sampleCount = 1
            descriptor.vertexFunction = vertexFunc
            descriptor.fragmentFunction = fragmentFunc
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.depthAttachmentPixelFormat = .depth32Float
            if let pipeline = try? device.makeRenderPipelineState(descriptor: descriptor) {
                pipelines.append(pipeline)
            }
        }
    }
    
}
