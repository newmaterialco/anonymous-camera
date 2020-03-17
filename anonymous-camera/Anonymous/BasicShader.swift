//
//  YUVToRGBShader.swift
//  ShaderKit
//
//  Created by Alisdair Mills on 03/12/2019.
//  Copyright © 2019 amills. All rights reserved.
//

import Foundation
import Metal

class BasicShader: BaseShader {
    
    override func generate(device: MTLDevice) {
        generateFrom(device: device, vertex: "oneInputVertex", fragment: "yuvToRgbFragment")
    }
    
}
