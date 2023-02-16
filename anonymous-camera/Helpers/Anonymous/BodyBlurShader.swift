//
//  BodyBlurShader.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 06/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class BodyBlurShader: BodyShader {

    var blurRadius: Float = 24.0
    private var blurTexture: MTLTexture?
    private var blurBuffer: MTLBuffer?
    
    override func coordBuffer(pass: Int) -> MTLBuffer? {
        if pass == 0 { return blurBuffer }
        return super.coordBuffer(pass: pass)
    }
    
    override func generate(device: MTLDevice) {
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "yuvToRgbFragment")
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "bodyBlurFragment")
    }
    
    override func generateFrom(device: MTLDevice, vertex: String, fragment: String) {
        super.generateFrom(device: device, vertex: vertex, fragment: fragment)
        if blurBuffer == nil {
            let blurCoordVertex: [Float] = [0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]
            let coordDataCount = blurCoordVertex.count * MemoryLayout<Float>.size
            blurBuffer = device.makeBuffer(bytes: blurCoordVertex, length: coordDataCount, options: [])
            blurBuffer?.label = "\(theClassName)BlurBuffer"
        }
    }
    
    override func addUniforms(pass: Int, encoder: MTLRenderCommandEncoder, device: MTLDevice, size: CGSize) {
        if pass == 1 {
            if let alphaTexture = alphaTexture {
                encoder.setFragmentTexture(alphaTexture, index: 3)
            }
            if let blurTexture = blurTexture {
                encoder.setFragmentTexture(blurTexture, index: 4)
            }
            var uniforms = BodyUniforms()
            uniforms.aspectRatio = (size.height / size.width).float
            uniforms.widthOfPixel = widthOfPixel
            uniforms.edge = edge
            uniforms.axis = axis
            uniforms.divider = divider
            uniforms.padding = 0.01
            uniforms.invert = invert
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<BodyUniforms>.size, index: 1)
        }
    }
    
    override func postRender(pass: Int, encoder: MTLRenderCommandEncoder, device: MTLDevice, drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer) {
        if pass == 0 {
            let descriptor = MTLTextureDescriptor()
            descriptor.depth = 1
            descriptor.width = drawable.texture.width
            descriptor.height = drawable.texture.height
            descriptor.textureType = drawable.texture.textureType
            descriptor.pixelFormat = drawable.texture.pixelFormat
            descriptor.usage = [.shaderRead, .shaderWrite]
            if let texture = device.makeTexture(descriptor: descriptor) {
                let kernel = MPSImageGaussianBlur(device: device, sigma: blurRadius)
                kernel.encode(commandBuffer: commandBuffer, sourceTexture: drawable.texture, destinationTexture: texture)
                blurTexture = texture
            }
        }
    }
    
}
