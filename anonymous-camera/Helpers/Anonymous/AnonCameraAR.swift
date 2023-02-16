//
//  AnonCameraAR.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 28/11/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import Foundation
import Metal
import CoreVideo
import AVFoundation
import ARKit
import MetalPerformanceShaders

public protocol AnonCameraARDelegate {
    func onBodyTexture(_ texture: Texture)
}

public class AnonCameraAR: NSObject, ImageSource {

    public let targets = TargetContainer()
    #if targetEnvironment(simulator)
    #else
    var videoTextureCache: CVMetalTextureCache?
    #endif
    var supportsFullYUVRange:Bool = false
    let captureAsYUV:Bool = false
    var yuvConversionRenderPipelineState:MTLRenderPipelineState? = nil
    var yuvLookupTable:[String:(Int, MTLDataType)] = [:]
    
    let frameRenderingSemaphore = DispatchSemaphore(value:1)
    let cameraProcessingQueue = DispatchQueue.global()
    let cameraFrameProcessingQueue = DispatchQueue(
        label: "com.sunsetlakesoftware.GPUImage.cameraFrameProcessingQueue",
        attributes: [])
    
    let framesToIgnore = 5
    var numberOfFramesCaptured = 0
    var totalFrameTimeDuringCapture:Double = 0.0
    var framesSinceLastCheck = 0
    var lastCheckTime = CFAbsoluteTimeGetCurrent()
    var matteGenerator: ARMatteGenerator?
    var delegate: AnonCameraARDelegate?
    
    public func sendOutput(texture: Texture?) {
        
        guard (frameRenderingSemaphore.wait(timeout:DispatchTime.now()) == DispatchTimeoutResult.success) else { return }
        
        cameraFrameProcessingQueue.async {
            #if targetEnvironment(simulator)
            #else
            if texture != nil {
                self.updateTargetsWithTexture(texture!)
            }
            self.frameRenderingSemaphore.signal()
            #endif
        }
    }
    
    public func startCapture() {
        #if targetEnvironment(simulator)
        #else
        let (pipelineState, lookupTable) = generateRenderPipelineState(device:sharedMetalRenderingDevice, vertexFunctionName:"twoInputVertex", fragmentFunctionName:"yuvConversionFullRangeFragment", operationName:"YUVToRGB")
        self.yuvConversionRenderPipelineState = pipelineState
        self.yuvLookupTable = lookupTable
        let _ = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)
        let _ = frameRenderingSemaphore.wait(timeout:DispatchTime.distantFuture)
        self.numberOfFramesCaptured = 0
        self.totalFrameTimeDuringCapture = 0
        self.frameRenderingSemaphore.signal()
        #endif
    }
    
    public func stopCapture() {
        let _ = frameRenderingSemaphore.wait(timeout:DispatchTime.distantFuture)
        self.frameRenderingSemaphore.signal()
    }
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt) {
        // Not needed for camera
    }

}

extension AnonCameraAR: ARSessionDelegate {
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard (frameRenderingSemaphore.wait(timeout:DispatchTime.now()) == DispatchTimeoutResult.success) else { return }
        
        let cameraFrame = frame.capturedImage
        if (CVPixelBufferGetPlaneCount(cameraFrame) < 2) {
            return
        }
        
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        
        CVPixelBufferLockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
        cameraFrameProcessingQueue.async {
            CVPixelBufferUnlockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            #if targetEnvironment(simulator)
            #else
            var texture:Texture?
            var bodyTexture: Texture?
            var luminanceTextureRef:CVMetalTexture? = nil
            var chrominanceTextureRef:CVMetalTexture? = nil
            let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .r8Unorm, bufferWidth, bufferHeight, 0, &luminanceTextureRef)
            let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .rg8Unorm, bufferWidth / 2, bufferHeight / 2, 1, &chrominanceTextureRef)
            
            if let concreteLuminanceTextureRef = luminanceTextureRef, let concreteChrominanceTextureRef = chrominanceTextureRef,
                let luminanceTexture = CVMetalTextureGetTexture(concreteLuminanceTextureRef), let chrominanceTexture = CVMetalTextureGetTexture(concreteChrominanceTextureRef) {
                let conversionMatrix:Matrix3x3 = colorConversionMatrix601FullRangeDefault
                let outputWidth:Int
                let outputHeight:Int
                outputWidth = bufferWidth
                outputHeight = bufferHeight
                let outputTexture = Texture(device:sharedMetalRenderingDevice.device, orientation:.portrait, width:outputWidth, height:outputHeight)
                
                convertYUVToRGB(pipelineState: self.yuvConversionRenderPipelineState!, lookupTable: self.yuvLookupTable,
                                luminanceTexture: Texture(orientation: .landscapeRight, texture: luminanceTexture),
                                chrominanceTexture: Texture(orientation: .landscapeRight, texture: chrominanceTexture),
                                resultTexture: outputTexture, colorConversionMatrix: conversionMatrix)
                
                if let delegate = self.delegate {
                    if self.matteGenerator == nil {
                        self.matteGenerator = ARMatteGenerator(device: sharedMetalRenderingDevice.device, matteResolution: .half)
                    }
                    if let matteGenerator = self.matteGenerator, let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() {
                        let alphaTexture = matteGenerator.generateMatte(from: frame, commandBuffer: commandBuffer)
                        bodyTexture = Texture(orientation: .landscapeRight, texture: alphaTexture)
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                        if let bodyTexture = bodyTexture {
                            delegate.onBodyTexture(bodyTexture)
                        }
                    }
                }
                texture = outputTexture
                if texture != nil {
                    self.updateTargetsWithTexture(texture!)
                }
                self.frameRenderingSemaphore.signal()
                
            }
            
            
            #endif
        }
    }
    
}
