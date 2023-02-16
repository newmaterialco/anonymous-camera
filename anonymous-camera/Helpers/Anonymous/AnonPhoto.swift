//
//  AnonPhoto.swift
//  faceblur
//
//  Created by Alisdair Mills on 02/10/2019.
//  Copyright © 2019 amills. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import VideoToolbox
import Accelerate

extension MTLTexture {

    func bytes() -> UnsafeMutableRawPointer {
        let width = self.width
        let height = self.height
        let rowBytes = self.width * 4
        let p = malloc(width * height * 4)
        self.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return p!
    }

    func toImage() -> CGImage? {
        let p = bytes()
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: p, size: selftureSize, releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        return cgImageRef
    }
}

typealias AnonPhotoReady = (_ : UIImage) -> Void

class AnonPhoto {
    
    var watermark: UIImage?
    static var viewportSize: CGSize = .zero
    static var resolution: CGSize = .zero
    
    func onImageReady(_ block: @escaping AnonPhotoReady) {
        imageReadyHandler = block
    }
    
    func addAnonBuffer(currentDrawable: CAMetalDrawable) {
        if let _ = anonImage { return }
        if let cgImage = currentDrawable.texture.toImage() {
            anonImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
            
            let orientation = MotionManager.shared.orientation
            if orientation == .landscapeLeft { anonImage = anonImage?.rotated(by: Measurement(value: -90, unit: .degrees)) }
            else if orientation == .landscapeRight { anonImage = anonImage?.rotated(by: Measurement(value: 90, unit: .degrees)) }
            else if orientation == .portraitUpsideDown { anonImage = anonImage?.rotated(by: Measurement(value: 180, unit: .degrees)) }
            
            if let anonImage = anonImage {
                let w = anonImage.size.width
                let h = anonImage.size.height
                var viewportAspect = AnonPhoto.viewportSize.width / AnonPhoto.viewportSize.height
                if orientation == .landscapeRight || orientation == .landscapeLeft {
                    viewportAspect = AnonPhoto.viewportSize.height / AnonPhoto.viewportSize.width
                }
                let aspect = w / h
                let stretch = viewportAspect / aspect
                let aspectW = stretch * w
                let x = (w - aspectW) / 2
                UIGraphicsBeginImageContextWithOptions(CGSize(width: w, height: h), false, anonImage.scale)
                anonImage.draw(in: CGRect(x: x, y: 0, width: aspectW, height: h))
                self.anonImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
            if let image = createImage() {
                DispatchQueue.main.async { self.imageReadyHandler?(image) }
            }
        }
    }
    
    // private
    private var imageReadyHandler: AnonPhotoReady?
    private var anonImage: UIImage?
    
    private func createImage() -> UIImage? {
        var compositeImage: UIImage?
        if let anonImage = anonImage {
            let sourceSize = anonImage.size
            var outputSize = anonImage.size
            if sourceSize.width > sourceSize.height {
                outputSize = CGSize(width: sourceSize.height * (4 / 3), height: sourceSize.height)
            }
            UIGraphicsBeginImageContext(outputSize)
            let rect = CGRect(x: (outputSize.width - sourceSize.width) / 2, y: (outputSize.height - sourceSize.height) / 2, width: sourceSize.width, height: sourceSize.height)
            anonImage.draw(in: rect)
            if let watermark = watermark {
                let rect = CGRect(x: outputSize.width - 20 - watermark.size.width, y: outputSize.height - 20 - watermark.size.height, width: watermark.size.width, height: watermark.size.height)
                watermark.draw(in: rect)
            }
            compositeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return compositeImage
    }
    
}
