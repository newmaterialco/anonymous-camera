//
//  FaceShader.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 06/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class FaceShader: BaseShader {
    
    var faces: [CGRect] = []
    var padding: Float = 0
    var divider: Float = 0
    var edge: Float = 0
    var axis: Float = 0
    var widthOfPixel: Float = 0.05
    var scale: Float = 1.0
    var renderSize: CGSize = .zero
    private var hasFaces: Float = 0
    
    override func obseleteForCurrentFrame() -> Bool {
        return faces.count == 0
    }
    
    override func updateCoords(device: MTLDevice, resolution: CGSize, viewport: CGSize) {
        super.updateCoords(device: device, resolution: resolution, viewport: viewport)
        renderSize = viewport
    }
    
    override func addUniforms(pass: Int, encoder: MTLRenderCommandEncoder, device: MTLDevice, size: CGSize) {
        var uniforms = FaceUniforms()
        uniforms.widthOfPixel = scale * widthOfPixel
        uniforms.aspectRatio = (size.height / size.width).float
        uniforms.padding = padding
        uniforms.edge = edge
        uniforms.axis = axis
        uniforms.divider = divider
        if faces.count > 0 { uniforms.hasFaces = 1.0 }
        else { uniforms.hasFaces = 0.0 }
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FaceUniforms>.size, index: 1)
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
                encoder.setFragmentTexture(texture, index: 3)
            }
            
        }
    }
    
}
