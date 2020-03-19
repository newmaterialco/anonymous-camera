//
//  FaceBlurShader.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 06/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class FaceBlurShader: FaceShader {
    
    var blurRadius: Float = 24.0
    private var blurTexture: MTLTexture?
    private var renderSize: CGSize = .zero
    
    override func generate(device: MTLDevice) {
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "yuvToRgbFragment")
        computeFrom(device: device, name: "faceBlurCompute")
    }
    
    override func updateCoords(device: MTLDevice, resolution: CGSize, viewport: CGSize) {
        super.updateCoords(device: device, resolution: resolution, viewport: viewport)
        renderSize = viewport
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
                let kernel = MPSImageGaussianBlur(device: device, sigma: scale * blurRadius)
                kernel.encode(commandBuffer: commandBuffer, sourceTexture: drawable.texture, destinationTexture: texture)
                blurTexture = texture
            }
        }
    }
    
    override func setComputeValues(encoder: MTLComputeCommandEncoder, device: MTLDevice, drawable: CAMetalDrawable) {
        encoder.setTexture(drawable.texture, index: 0)
        encoder.setTexture(blurTexture, index: 1)
        encoder.setTexture(drawable.texture, index: 2)
        var uniforms = FaceUniforms()
        uniforms.widthOfPixel = widthOfPixel
        uniforms.aspectRatio = (renderSize.width / renderSize.height).float
        uniforms.padding = padding
        uniforms.edge = edge
        uniforms.axis = axis
        uniforms.divider = divider
        if faces.count > 0 { uniforms.hasFaces = 1.0 }
        else { uniforms.hasFaces = 0.0 }
        encoder.setBytes(&uniforms, length: MemoryLayout<FaceUniforms>.size, index: 1)
        if faces.count > 0 {
            var tmp: [Float] = []
            for face in faces {
                tmp.append((1.0 - face.minX.float) - face.width.float)
                tmp.append(face.minY.float)
                tmp.append(face.width.float)
                tmp.append(face.height.float)
            }
            let descriptor = MTLTextureDescriptor()
            descriptor.textureType = .type1D
            descriptor.pixelFormat = .r32Float
            descriptor.width = tmp.count
            descriptor.height = 1
            descriptor.depth = 1
            if let texture = device.makeTexture(descriptor: descriptor) {
                let region = MTLRegion(origin: MTLOrigin(), size: MTLSize(width: descriptor.width, height: 1, depth: 1))
                texture.replace(region: region, mipmapLevel: 0, withBytes: &tmp, bytesPerRow: MemoryLayout<Float>.size * tmp.count)
                encoder.setTexture(texture, index: 3)
            }
            
        }
    }
    
}
