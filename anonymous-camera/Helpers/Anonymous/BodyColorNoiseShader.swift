//
//  BodyColorNoiseShader.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 04/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class BodyColorNoiseShader: BodyShader {

    override func generate(device: MTLDevice) {
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "colorNoiseBodyFragment")
    }
    
}
