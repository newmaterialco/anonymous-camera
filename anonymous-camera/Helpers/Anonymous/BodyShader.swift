//
//  BodyShader.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 06/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class BodyShader: BaseShader, ARDepthShader {    
    
    var divider: Float = 0
    var edge: Float = 0
    var axis: Float = 0
    var widthOfPixel: Float = 0.05
    var scale: Float = 1.0
    var alphaTexture: MTLTexture?
    var padding: Float = 0.0
    var invert: Float = 0.0
    
    override func addUniforms(pass: Int, encoder: MTLRenderCommandEncoder, device: MTLDevice, size: CGSize) {
        if let alphaTexture = alphaTexture {
            encoder.setFragmentTexture(alphaTexture, index: 3)
        }
        var uniforms = BodyUniforms()
        uniforms.aspectRatio = (size.height / size.width).float
        uniforms.widthOfPixel = widthOfPixel
        uniforms.edge = edge
        uniforms.axis = axis
        uniforms.divider = divider
        uniforms.padding = padding
        uniforms.invert = invert
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<BodyUniforms>.size, index: 1)
    }
    
    func useDepthTexture(_ texture: MTLTexture) {
        alphaTexture = texture
    }

    
}
