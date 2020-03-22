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
    private var blurBuffer: MTLBuffer?
    
    override func coordBuffer(pass: Int) -> MTLBuffer? {
        if pass == 0 { return blurBuffer }
        return super.coordBuffer(pass: pass)
    }
    
    override func needsSourceAspect() -> Bool {
        return true
    }
    
    override func generate(device: MTLDevice) {
        generateFrom(device: device, vertex: "nonScaledInputVertex", fragment: "yuvToRgbFragment")
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "faceBlurFragment")
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
            if let blurTexture = blurTexture {
                encoder.setFragmentTexture(blurTexture, index: 3)
            }
            if faces.count > 0 {
                var tmp: [Float] = []
                for face in faces {
                    tmp.append(face.minY.float)
                    if CameraShader.shared.frontFacing { tmp.append(face.minX.float) }
                    else { tmp.append((1.0 - face.minX.float) - face.width.float) }
                    tmp.append(face.height.float)
                    tmp.append(face.width.float)
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
                    encoder.setFragmentTexture(texture, index: 4)
                }
            }
            var uniforms = FaceUniforms()
            uniforms.widthOfPixel = widthOfPixel
            uniforms.aspectRatio = (size.height / size.width).float
            uniforms.padding = padding
            uniforms.edge = edge
            uniforms.axis = axis
            uniforms.divider = divider
            if faces.count > 0 { uniforms.hasFaces = 1.0 }
            else { uniforms.hasFaces = 0.0 }
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FaceUniforms>.size, index: 1)
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
                let kernel = MPSImageGaussianBlur(device: device, sigma: scale * blurRadius)
                kernel.encode(commandBuffer: commandBuffer, sourceTexture: drawable.texture, destinationTexture: texture)
                blurTexture = texture
            }
        }
    }
    
}
