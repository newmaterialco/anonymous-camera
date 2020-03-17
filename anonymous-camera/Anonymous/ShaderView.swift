//
//  ShaderView.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 07/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import UIKit
import MetalKit

class ShaderView: MTKView {
    
    private var lastRatio: CGFloat = 0.0
    var desiredRatio: CGFloat = 9.0 / 16.0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let sView = superview, sView.width != 0, lastRatio != desiredRatio {
            let aspectRatio = sView.width / sView.height
            var desiredWidth = sView.width
            var desiredHeight = sView.height
            if desiredRatio > aspectRatio { desiredWidth = sView.height * desiredRatio }
            else if desiredRatio < aspectRatio { desiredHeight = sView.width / desiredRatio }
            width = round(desiredWidth)
            height = round(desiredHeight)
            x = (sView.width - width) / 2
            y = 0
            lastRatio = desiredRatio
            print("updated frame to \(frame)")
        }
    }

}
