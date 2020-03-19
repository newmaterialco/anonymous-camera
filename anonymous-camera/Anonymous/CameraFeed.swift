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
    
    public static func availableTypes() {
        
    }
    
    func stop() {
        if let _ = captureSession { destroySession() }
        if let _ = arSession { destroyARSession() }
    }
    
    func start(type: CameraFeedType) {
        if type == .front || type == .back {
            if let _ = captureSession { destroySession() }
            if let _ = arSession { destroyARSession() }
            var position: AVCaptureDevice.Position = .front
            if type == .back { position = .back }
            createCaptureSession(position: position)
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
    private let cameraFrameProcessingQueue = DispatchQueue(label: "amills.ShaderKit", attributes: [])
    private let cameraProcessingQueue = DispatchQueue.global()
    private var captureSession: AVCaptureSession?
    private var inputCamera: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var arSession: ARSession?
    private var outputType: CameraFeedType = .none
    
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
    
    private func createCaptureSession(position: AVCaptureDevice.Position) {
        let session = AVCaptureSession()
        session.beginConfiguration()
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position)
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
        
        videoOutput = output
        captureSession = session
        
        session.startRunning()
    }
    
}

extension CameraFeed: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.captureOutput(output, sampleBuffer: sampleBuffer, connection: connection, type: outputType)
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
