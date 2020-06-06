//
//  AnonCoreImageProcessing.swift
//  image.processing
//
//  Created by Alisdair Mills on 05/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import Foundation
import CoreImage
import Vision
import UIKit

public class AnonCoreImageProcessing {
    
    public enum MaskType {
        case blur
        case color
        case noise
        case pixel
    }
    
    private static var instance: AnonCoreImageProcessing?
    public static var shared: AnonCoreImageProcessing {
        if instance == nil {
            instance = AnonCoreImageProcessing()
        }
        return instance!
    }
    
    public func process(ciImage: CIImage, maskType: MaskType, watermark: UIImage?, completion: @escaping (_: CIImage?) -> Void) {
        
    }
    
}
