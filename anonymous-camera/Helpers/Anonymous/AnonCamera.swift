//
//  AnonCamera.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 22/10/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

import UIKit
import AVKit

public protocol AnonCameraDelegate {
    func onCaptureBuffer(_ sampleBuffer: CMSampleBuffer)
}

class AnonCamera: NSObject {
    
    public var delegate: AnonCameraDelegate?
    public var captureDeviceResolution: CGSize = .zero
    
    init(position: AVCaptureDevice.Position) {
        super.init()
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)
        let (pipelineState, lookupTable) = generateRenderPipelineState(device: sharedMetalRenderingDevice, vertexFunctionName: "twoInputVertex", fragmentFunctionName: "yuvConversionFullRangeFragment", operationName: "YUVToRGB")
        yuvConversionRenderPipelineState = pipelineState
        yuvLookupTable = lookupTable
        session = setupAVCaptureSession(position: position)
    }
    
    public func startCapture() {
        session?.startRunning()
    }
    
    public func stopCapture() {
        delegate = nil
        videoDataOutput?.setSampleBufferDelegate(nil, queue:nil)
        if let session = session {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }
    
    // private
    private let cameraTargets = TargetContainer()
    private var session: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue: DispatchQueue?
    private var captureDevice: AVCaptureDevice?
    private var videoTextureCache: CVMetalTextureCache?
    private let conversionMatrix: Matrix3x3 = colorConversionMatrix601FullRangeDefault
    private var yuvLookupTable: [String: (Int, MTLDataType)]?
    private var yuvConversionRenderPipelineState: MTLRenderPipelineState?
    
    private func setupAVCaptureSession(position: AVCaptureDevice.Position) -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        do {
            let inputDevice = try configureCamera(for: captureSession, position: position)
            configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: captureSession)
            return captureSession
        }
        catch {}
        self.teardownAVCapture()
        return nil
    }
    
    fileprivate func configureCamera(for captureSession: AVCaptureSession, position: AVCaptureDevice.Position) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position)
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                if let highestResolution = highestResolution420Format(for: device) {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()
                    return (device, highestResolution.resolution)
                }
            }
        }
        
        throw NSError(domain: "AnonCamera", code: 1, userInfo: nil)
    }
    
    private func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        let videoDataOutputQueue = DispatchQueue(label: "anonymouscamera.AnonCamera")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        videoDataOutput.connection(with: .video)?.isEnabled = true
        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue
        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }
    
    private func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)
        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format
            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }
        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }
        return nil
    }
    
    private func teardownAVCapture() {
        videoDataOutput = nil
        videoDataOutputQueue = nil
    }
    
    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        if let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer), let videoTextureCache = videoTextureCache {
            let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
            let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
            let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            var texture:Texture?
            var luminanceTextureRef:CVMetalTexture? = nil
            var chrominanceTextureRef:CVMetalTexture? = nil
            let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, cameraFrame, nil, .r8Unorm, bufferWidth, bufferHeight, 0, &luminanceTextureRef)
            let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, cameraFrame, nil, .rg8Unorm, bufferWidth / 2, bufferHeight / 2, 1, &chrominanceTextureRef)
            
            if let concreteLuminanceTextureRef = luminanceTextureRef, let concreteChrominanceTextureRef = chrominanceTextureRef,
            let luminanceTexture = CVMetalTextureGetTexture(concreteLuminanceTextureRef), let chrominanceTexture = CVMetalTextureGetTexture(concreteChrominanceTextureRef), let yuvLookupTable = yuvLookupTable, let yuvConversionRenderPipelineState = yuvConversionRenderPipelineState {
                
                let outputTexture = Texture(device:sharedMetalRenderingDevice.device, orientation:.portrait, width: bufferHeight, height: bufferWidth, timingStyle: .videoFrame(timestamp: Timestamp(currentTime)))
                
                convertYUVToRGB(pipelineState: yuvConversionRenderPipelineState, lookupTable: yuvLookupTable, luminanceTexture:Texture(orientation: .landscapeRight, texture: luminanceTexture), chrominanceTexture: Texture(orientation: .landscapeRight, texture: chrominanceTexture), resultTexture: outputTexture, colorConversionMatrix: conversionMatrix)
                texture = outputTexture
            }
            
            if let texture = texture {
                updateTargetsWithTexture(texture)
            }
        }
        
    }
    
}

extension AnonCamera: ImageSource {
    var targets: TargetContainer { return cameraTargets }
    func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt) {}
}

extension AnonCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.onCaptureBuffer(sampleBuffer)
        processFrame(sampleBuffer)
    }
    
}
