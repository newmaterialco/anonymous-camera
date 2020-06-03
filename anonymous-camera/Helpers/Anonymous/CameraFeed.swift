//
//  Camera.swift
//  ShaderKit
//
//  Created by Alisdair Mills on 03/12/2019.
//  Copyright © 2019 amills. All rights reserved.
//

import Foundation
import AVFoundation
import Metal
import ARKit

extension AVCaptureDevice {
    func set(frameRate: Double) {
    guard let range = activeFormat.videoSupportedFrameRateRanges.first,
        range.minFrameRate...range.maxFrameRate ~= frameRate
        else {
            print("Requested FPS is not supported by the device's activeFormat !")
            return
    }

    do { try lockForConfiguration()
        activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        unlockForConfiguration()
    } catch {
        print("LockForConfiguration failed with error: \(error.localizedDescription)")
    }
  }
}

protocol CameraFeedDelegate {
    func captureOutput(_ output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection, type: CameraFeed.CameraFeedType)
    func captureAROutput(_ session: ARSession, frame: ARFrame, type: CameraFeed.CameraFeedType)
    func capturedFaceRects(_ rects: [CGRect])
}

class CameraFeed: NSObject {
    
    var delegate: CameraFeedDelegate?
    
    enum CameraFeedType {
        case none
        case front
        case back
        case backAR
        case backUltraWide
        case backTelephoto
    }
    
    // singleton set up - only one camera instance allowed
    private static var instance: CameraFeed?
    static var shared: CameraFeed {
        if instance == nil {
            instance = CameraFeed()
        }
        return instance!
    }
    
    static func availableTypes() -> [CameraFeedType] {
        var tmp: [CameraFeedType] = [.front, .back]
        if Platform.hasDepthSegmentation { tmp.append(.backAR) }
        var discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .back)
        if !discovery.devices.isEmpty { tmp.append(.backUltraWide) }
        discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTelephotoCamera], mediaType: .video, position: .back)
        if !discovery.devices.isEmpty { tmp.append(.backTelephoto) }
        return tmp
    }
    
    func resume() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .restricted || status == .denied { self.stop() }
        else if captureSession == nil, arSession == nil, status == .authorized, outputType != .none {
            start(type: outputType)
        }
    }
    
    func stop() {
        if let _ = captureSession { destroySession() }
        if let _ = arSession { destroyARSession() }
    }
    
    func start(type: CameraFeedType) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .restricted || status == .denied {
            self.outputType = type
            return
        }
        if type != .none && type != .backAR {
            if let _ = captureSession { destroySession() }
            if let _ = arSession { destroyARSession() }
            var position: AVCaptureDevice.Position = .front
            if type == .back { position = .back }
            if type == .backUltraWide { createCaptureSession(position: position, lens: .builtInUltraWideCamera) }
            else if type == .backTelephoto { createCaptureSession(position: position, lens: .builtInTelephotoCamera) }
            else { createCaptureSession(position: position) }
        }
        else if type == .backAR {
            if let _ = captureSession { destroySession() }
            if let _ = arSession { destroyARSession() }
            let arConfiguration = ARWorldTrackingConfiguration()
            arConfiguration.frameSemantics = .personSegmentationWithDepth
            arConfiguration.providesAudioData = false
            arSession = ARSession()
            arSession?.delegate = self
            arSession?.run(arConfiguration)
            arSession?.pause()
            DispatchQueue.main.async {
                self.arSession?.run(arConfiguration)
            }            
        }
        outputType = type
    }
    
    // private
    private let cameraProcessingQueue = DispatchQueue.global()
    private var captureSession: AVCaptureSession?
    private var inputCamera: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var arSession: ARSession?
    private var outputType: CameraFeedType = .none
    private var lastFacesDetected = 0.0
    
    private func destroySession() {
        if let captureSession = captureSession {
            captureSession.stopRunning()
        }
        if let output = videoOutput {
            output.setSampleBufferDelegate(nil, queue:nil)
        }
        captureSession = nil
        videoOutput = nil
    }
    
    private func destroyARSession() {
        if let session = arSession {
            session.pause()
            session.delegate = nil
        }
        arSession = nil
    }
    
    private func createCaptureSession(position: AVCaptureDevice.Position, lens: AVCaptureDevice.DeviceType = .builtInWideAngleCamera) {
        let session = AVCaptureSession()
        session.beginConfiguration()
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [lens], mediaType: .video, position: position)
        for device in discovery.devices {
            #if os(iOS)
            if device.position == position { inputCamera = device }
            #else
            inputCamera = device
            #endif
        }
        if let inputCamera = inputCamera {
            videoInput = try? AVCaptureDeviceInput(device: inputCamera)
            inputCamera.set(frameRate: 60)
        }
        if let videoInput = videoInput {
            if session.canAddInput(videoInput) { session.addInput(videoInput) }
        }
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:NSNumber(value:Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))]
        if session.canAddOutput(output) { session.addOutput(output) }
        session.sessionPreset = .high
        session.commitConfiguration()
        output.setSampleBufferDelegate(self, queue: cameraProcessingQueue)
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: cameraProcessingQueue)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
        }
        
        videoOutput = output
        captureSession = session
        
        session.startRunning()
    }
    
}

extension CameraFeed: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.captureOutput(output, sampleBuffer: sampleBuffer, connection: connection, type: outputType)
        let timeSinceLastFace = Date().timeIntervalSince1970 - lastFacesDetected
        if timeSinceLastFace > 0.2 {
            delegate?.capturedFaceRects([])
        }
    }
}

extension CameraFeed: ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let time = Date().timeIntervalSince1970
        let frameTime = frame.timestamp
        let uptime = ProcessInfo.processInfo.systemUptime
        let offset = time - uptime
        let adjustedFrameTime = offset + frameTime
        let diff = time - adjustedFrameTime
        if diff < 0.1 {
            delegate?.captureAROutput(session, frame: frame, type: outputType)
        }
    }
}

extension CameraFeed: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var tmp: [CGRect] = []
        for face in metadataObjects {
            if face.type == .face { tmp.append(face.bounds) }
        }
        delegate?.capturedFaceRects(tmp)
        lastFacesDetected = Date().timeIntervalSince1970
    }
}
