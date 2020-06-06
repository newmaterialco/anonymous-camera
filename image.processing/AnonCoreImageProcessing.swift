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
            instance?.configureRequest()
        }
        return instance!
    }
    
    public func process(ciImage: CIImage, maskType: MaskType, watermark: UIImage?, color: UIColor?, completion: @escaping (_: UIImage?) -> Void) {
        if let _ = activeImage {
            completion(nil)
            return
        }
        handler = completion
        activeImage = ciImage
        processType = maskType
        fillColor = color
        DispatchQueue.global(qos: .background).async {
            if let detectRequest = self.detectRequest {
                let visionImage = VNImageRequestHandler(ciImage: ciImage, options: [:])
                try? visionImage.perform([detectRequest])
            }
        }
    }
    
    private var detectRequest: VNDetectFaceRectanglesRequest?
    private var activeImage: CIImage?
    private var processType: MaskType = .blur
    private var handler: ((_: UIImage?) -> Void)?
    private var fillColor: UIColor?
    
    private func configureRequest() {
        detectRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, _) in
            if let results = request.results as? [VNDetectedObjectObservation] {
                self.processImage(rects: results)
            }
        })
    }
    
    private func processImage(rects: [VNDetectedObjectObservation]) {
        let ctx = CIContext()
        if let activeImage = activeImage, let cgImage = ctx.createCGImage(activeImage, from: activeImage.extent) {
            UIGraphicsBeginImageContextWithOptions(activeImage.extent.size, false, 1)
            if let context = UIGraphicsGetCurrentContext() {
                context.translateBy(x: 0, y: activeImage.extent.size.height)
                context.scaleBy(x: 1.0, y: -1.0)
                let rect = CGRect(x: 0, y: 0, width: activeImage.extent.size.width, height: activeImage.extent.size.height)
                context.draw(cgImage, in: rect)
                context.saveGState()
                var maskImage: CIImage?
                if processType == .blur, let blurFilter = CIFilter(name: "CIGaussianBlur") {
                    blurFilter.setValue(activeImage, forKey: kCIInputImageKey)
                    blurFilter.setValue(48, forKey: "inputRadius")
                    maskImage = blurFilter.value(forKey: kCIOutputImageKey) as? CIImage
                }
                else if processType == .pixel, let pixelFilter = CIFilter(name: "CIPixellate") {
                    pixelFilter.setValue(activeImage, forKey: kCIInputImageKey)
                    pixelFilter.setValue(48, forKey: "inputScale")
                    maskImage = pixelFilter.value(forKey: kCIOutputImageKey) as? CIImage
                }
                else if processType == .noise, let noiseFilter = CIFilter(name: "CIRandomGenerator") {
                    noiseFilter.setDefaults()
                    noiseFilter.setDefaults()
                    maskImage = noiseFilter.outputImage?.cropped(to: activeImage.extent)
                }
                else if processType == .color {
                    let fillColor = self.fillColor ?? UIColor.black
                    fillColor.setFill()
                }
                var maskCGImage: CGImage?
                if let maskImage = maskImage { maskCGImage = ctx.createCGImage(maskImage, from: activeImage.extent) }
                for rect in rects {
                    let r = rect.boundingBox
                    let w = r.width * activeImage.extent.size.width
                    let h = r.height * activeImage.extent.size.height
                    let x = r.minX * activeImage.extent.size.width
                    let y = r.minY * activeImage.extent.size.height
                    var max = w
                    if h > max { max = h }
                    max *= 1.25
                    var rect = CGRect(x: x, y: y, width: w, height: h)
                    rect = CGRect(x: rect.midX - (max / 2), y: rect.midY - (max / 2), width: max, height: max)
                    context.addEllipse(in: rect)
                }
                if let maskCGImage = maskCGImage {
                    let imageRect = CGRect(x: 0, y: 0, width: activeImage.extent.size.width, height: activeImage.extent.size.height)
                    context.clip()
                    if processType == .noise {
                        UIColor.gray.setFill()
                        context.addRect(imageRect)
                        context.drawPath(using: CGPathDrawingMode.fill)
                    }
                    context.draw(maskCGImage, in: imageRect)
                }
                else { context.drawPath(using: CGPathDrawingMode.fill) }
                context.restoreGState()
            }
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async { self.handler?(img) }
            self.activeImage = nil
        }
        
    }
    
}
