//
//  CameraShader.swift
//  ShaderKit
//
//  Created by Alisdair Mills on 03/12/2019.
//  Copyright © 2019 amills. All rights reserved.
//

import Foundation
import AVFoundation
import MetalKit
import Metal
import ARKit
import SwifterSwift

public protocol CameraShaderSampleDelegate {
    func captureOutput(_ output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection, skip: Bool)
}
public protocol CameraShaderImageDelegate {
    func didDrawImage(drawable: CAMetalDrawable)
}
public protocol CameraShaderVideoDelegate {
    func didDrawFrame(texture: MTLTexture, timestamp: Double)
}
public protocol CameraShaderARDelegate {
    func willRenderAR()
}

extension NSObject {
    var theClassName: String {
        return NSStringFromClass(type(of: self))
    }
}

public class CameraShader: NSObject {
    
    public var sampleDelegate: CameraShaderSampleDelegate?
    public var arDelegate: CameraShaderARDelegate?
    public var renderResolution = CGSize.zero
    public var sourceResolution = CGSize.zero
    
    private static var instance: CameraShader?
    public static var shared: CameraShader {
        if instance == nil {
            instance = CameraShader()
        }
        return instance!
    }
    
    public var frontFacing: Bool {
        if cameraType == .front { return true }
        return false
    }
    
    public func shader(at: Int) -> BaseShader? {
        return activeShaders[at]
    }
    
    public func takeImage(feed: Int, delegate: CameraShaderImageDelegate?) {
        photoDelegate = delegate
        photoFeed = feed
    }
    
    public func takeVideo(feed: Int, delegate: CameraShaderVideoDelegate?) {
        videoDelegate = delegate
        videoFeed = feed
    }
    
    public func useShader(shader: BaseShader, index: Int) {
        if let generatedShader = shaders[shader.theClassName] {
            activeShaders[index] = generatedShader
        }
        else if let _ = views.first, let device = sharedMetalDevice {
            shader.generate(device: device)
            shaders[shader.theClassName] = shader
            activeShaders[index] = shader
            if let renderView = views.first {
                if renderView.width != 0 {
                    shader.updateCoords(device: device, resolution: sourceResolution, viewport: renderView.size)
                }
            }
        }
    }
    
    public func stop() {
        CameraFeed.shared.stop()
    }
    
    public func start(mtkViews: [MTKView], position: AVCaptureDevice.Position, useARFeeed: Bool) {
        shouldMirror = false
        if useARFeeed && position == .back { CameraFeed.shared.start(type: .backAR) }
        else {
            if position == .front {
                CameraFeed.shared.start(type: .front)
                shouldMirror = true
            }
            else { CameraFeed.shared.start(type: .back) }
        }
        sharedMetalDevice = MTLCreateSystemDefaultDevice()
        loadMetal()
        views = mtkViews
        var index = 0
        for mtkView in views {
            mtkView.isPaused = true
            mtkView.enableSetNeedsDisplay = false
            mtkView.framebufferOnly = false
            mtkView.device = sharedMetalDevice
            mtkView.autoResizeDrawable = true
            mtkView.depthStencilPixelFormat = .depth32Float
            mtkView.colorPixelFormat = .bgra8Unorm
            mtkView.sampleCount = 1
            mtkView.drawableSize = CGSize(width: 1080, height: 1920)
            useShader(shader: basicShader, index: index)
            index += 1
        }
        CameraFeed.shared.delegate = self
    }
    
    // private
    private static let kMaxBuffersInFlight = 3
    private var views: [MTKView] = []
    private var shaders: [String: BaseShader] = [:]
    private var activeShaders: [Int: BaseShader] = [:]
    private var commandQueue: MTLCommandQueue?
    private var capturedImageTextureCache: CVMetalTextureCache?
    private var capturedImageTextureY: CVMetalTexture?
    private var capturedImageTextureCbCr: CVMetalTexture?
    private let inFlightSemaphore = DispatchSemaphore(value: kMaxBuffersInFlight)
    private var currentPixelBuffer: CVPixelBuffer?
    private var shouldMirror = false
    private var cameraType: CameraFeed.CameraFeedType = .none
    private var cameraTypeChange = false
    private var hasNewBuffer = false
    private var renderingFrame = false
    private var basicShader = BasicShader()
    private var matteGenerator: ARMatteGenerator?
    private var alphaTexture: MTLTexture?
    private var arFrame: ARFrame?
    private var frameTime: Double = 0.0
    private var receivedFrames = 0
    private var sentFrames = 0
    private var sharedMetalDevice: MTLDevice?
    private var photoDelegate: CameraShaderImageDelegate?
    private var videoDelegate: CameraShaderVideoDelegate?
    private var photoFeed = -1
    private var videoFeed = -1
    private var frameSkip = 0
    private var viewHeights: [Int: CGFloat] = [:]
    
    private func loadMetal() {
        if let device = sharedMetalDevice {
            var textureCache: CVMetalTextureCache?
            CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
            capturedImageTextureCache = textureCache
            commandQueue = device.makeCommandQueue()
        }
    }
    
    private func update() {
        if let _ = videoDelegate { }
        else {
            sentFrames = 0
            receivedFrames = 0
        }
        if !hasNewBuffer { return }
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        if let commandBuffer = commandQueue?.makeCommandBuffer() {
            renderingFrame = true
            let thisFrameTime = frameTime
            commandBuffer.label = "\(theClassName)Command"
            var textures = [capturedImageTextureY, capturedImageTextureCbCr]
            commandBuffer.addCompletedHandler { commandBuffer in
                self.inFlightSemaphore.signal()
                self.renderingFrame = false
                if let videoDelegate = self.videoDelegate {
                    let renderView = self.views[self.videoFeed]
                    if let currentDrawable = renderView.currentDrawable {
                        if self.sentFrames < self.receivedFrames {
                            self.sentFrames += 1
                            videoDelegate.didDrawFrame(texture: currentDrawable.texture, timestamp: thisFrameTime)
                        }
                    }
                }
                if let photoDelegate = self.photoDelegate {
                    let renderView = self.views[self.photoFeed]
                    if let currentDrawable = renderView.currentDrawable {
                        photoDelegate.didDrawImage(drawable: currentDrawable)
                    }
                }
                textures.removeAll()
            }
            if let pixelBuffer = currentPixelBuffer {
                if CVPixelBufferGetPlaneCount(pixelBuffer) > 1 {
                    capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
                    capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
                    var index = 0
                    for view in views {
                        if let device = sharedMetalDevice, let passDescriptor = view.currentRenderPassDescriptor, let currentDrawable = view.currentDrawable, let renderDescriptor = passDescriptor.copy() as? MTLRenderPassDescriptor, let capturedImageTextureY = capturedImageTextureY, let capturedImageTextureCbCr = capturedImageTextureCbCr, var usedShader = activeShaders[index] {
                            if usedShader.obseleteForCurrentFrame() { usedShader = basicShader }
                            if let arDepthShader = usedShader as? ARDepthShader {
                                if let matteGenerator = matteGenerator, let arFrame = arFrame {
                                    arDepthShader.useDepthTexture(matteGenerator.generateMatte(from: arFrame, commandBuffer: commandBuffer))
                                }
                            }
                            var size = CGSize(width: currentDrawable.texture.width, height: currentDrawable.texture.height)
                            if usedShader.needsSourceAspect() {
                                size = CGSize(width: sourceResolution.height, height: sourceResolution.width)
                            }
                            if cameraTypeChange && index == 0 && view.width > 0 { updateRenderLayer() }
                            else {
                                var viewHeight: CGFloat = 0.0
                                if let h = viewHeights[index] { viewHeight = h }
                                if viewHeight != view.height {
                                    updateRenderLayer()
                                    viewHeights[index] = view.height
                                }
                            }
                            if usedShader.hasRenders() {
                                var pass = 0
                                while pass != -1 {
                                    if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) {
                                        encoder.label = "\(theClassName)Render"
                                        let passAgain = usedShader.render(pass: pass, encoder: encoder, device: device, texY: capturedImageTextureY, texCbCr: capturedImageTextureCbCr, mirrored: shouldMirror, size: size)
                                        let thisPass = pass
                                        if passAgain { pass += 1 }
                                        else { pass = -1 }
                                        encoder.endEncoding()
                                        usedShader.postRender(pass: thisPass, encoder: encoder, device: device, drawable: currentDrawable, commandBuffer: commandBuffer)
                                    }
                                }
                            }
                            if usedShader.hasComputes() {
                                var pass = 0
                                while pass != -1 {
                                    if let compute = commandBuffer.makeComputeCommandEncoder() {
                                        compute.label = "\(theClassName)Compute"
                                        let passAgain = usedShader.compute(pass: pass, encoder: compute, device: device, drawable: currentDrawable)
                                        if passAgain { pass += 1 }
                                        else { pass = -1 }
                                        compute.endEncoding()
                                    }
                                }
                            }
                            renderResolution = CGSize(width: currentDrawable.texture.width, height: currentDrawable.texture.height)
                            commandBuffer.present(currentDrawable)
                            index += 1
                        }
                    }
                }
            }
            commandBuffer.commit()
        }
    }
    
    private func updateRenderLayer() {
        if let renderView = views.first, let device = sharedMetalDevice {
            for (_, shader) in shaders {
                shader.updateCoords(device: device, resolution: sourceResolution, viewport: renderView.size)
            }
        }
        cameraTypeChange = false
    }
    
    private func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        if let capturedImageTextureCache = capturedImageTextureCache {
            let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
            var texture: CVMetalTexture? = nil
            let status = CVMetalTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
            if status != kCVReturnSuccess { texture = nil }
            return texture
        }
        return nil
    }
    
}

extension CameraShader: CameraFeedDelegate {
    func captureOutput(_ output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection, type: CameraFeed.CameraFeedType) {
        if let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer) {
            frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            currentPixelBuffer = cameraFrame as CVPixelBuffer
            hasNewBuffer = true
            if let _ = videoDelegate {
                receivedFrames += 1
            }
            if type != cameraType, let currentPixelBuffer = currentPixelBuffer {
                let width = CVPixelBufferGetWidth(currentPixelBuffer)
                let height = CVPixelBufferGetHeight(currentPixelBuffer)
                sourceResolution = CGSize(width: width, height: height)
                cameraTypeChange = true
                cameraType = type
            }
        }
        var skip = false
        if renderingFrame { skip = true }
        sampleDelegate?.captureOutput(output, sampleBuffer: sampleBuffer, connection: connection, skip: skip)
        for view in views { view.draw() }
        DispatchQueue.main.sync { self.update() }
    }
    func captureAROutput(_ session: ARSession, frame: ARFrame, type: CameraFeed.CameraFeedType) {
        if let _ = videoDelegate {
            frameSkip += 1
            if frameSkip == 2 { frameSkip = 0 }
            else { return }
        }
        arDelegate?.willRenderAR()
        currentPixelBuffer = frame.capturedImage
        let time = Date().timeIntervalSince1970
        let fTime = frame.timestamp
        let uptime = ProcessInfo.processInfo.systemUptime
        let offset = time - uptime
        frameTime = offset + fTime
        hasNewBuffer = true
        if let _ = videoDelegate {
            receivedFrames += 1
        }
        if type != cameraType, let currentPixelBuffer = currentPixelBuffer {
            let width = CVPixelBufferGetWidth(currentPixelBuffer)
            let height = CVPixelBufferGetHeight(currentPixelBuffer)
            sourceResolution = CGSize(width: width, height: height)
            cameraTypeChange = true
            cameraType = type
        }
        if matteGenerator == nil {
            if let device = sharedMetalDevice {
                matteGenerator = ARMatteGenerator(device: device, matteResolution: .full)
            }
        }
        arFrame = frame
        for view in views { view.draw() }
        update()
    }
}

