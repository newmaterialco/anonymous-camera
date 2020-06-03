//
//  FaceColorFillShader.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 03/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class FaceColorFillShader: FaceShader {
    
    override func generate(device: MTLDevice) {
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "colorFillFragment")
    }
    
    override func needsSourceAspect() -> Bool {
        return true
    }
    
}
