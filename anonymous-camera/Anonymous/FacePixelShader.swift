//
//  FacePixelShader.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 05/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class FacePixelShader: FaceShader {
    
    override func generate(device: MTLDevice) {
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "pixellateFragment")
    }
    
    override func needsSourceAspect() -> Bool {
        return true
    }
    
}
