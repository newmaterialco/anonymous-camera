//
//  Anon.swift
//  faceblur
//
//  Created by Alisdair Mills on 26/09/2019.
//  Copyright © 2019 amills. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation
import Vision
import SwifterSwift
import Photos
import ARKit
import MetalKit

extension CGRect {
    public var centerX: CGFloat {
        get {return minX + (width * 0.5)}
    }
    public var centerY: CGFloat {
        get {return minY + (height * 0.5)}
    }
    public var center: CGPoint {
        get {return CGPoint(x: centerX, y: centerY)}
    }
}
extension CGPoint {
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return (self - point).length()
    }
    func length() -> CGFloat {
        return sqrt(x * x + y * y)
    }
}

struct Platform {
    static var hasDepthSegmentation: Bool {
        if #available(iOS 13.0, *) {
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                return true
            }
        }
        return false
    }
}

typealias AnonSavedToPhotos = (_ : Bool) -> Void
typealias AnonSavedToPhotoLibrary = (_ : Bool, _ : String) -> Void
typealias AnonSelfieRotation = (_: Bool, _ : Double, _: Double) -> Void

protocol AnonDelegate {
    func rotationChange(orientation: UIDeviceOrientation)
    func didSwitch(from: Anon.AnonState, to: Anon.AnonState)
    func updated(faces: [Anon.AnonFace])
}

class Anon: NSObject {
    
    struct CapturedItem {
        let localIdentifier: String
        let image: UIImage?
        let url: URL?
    }
    
    var availableLens: [CameraLens] {
        var tmp: [CameraLens] = [.normal]
        let types = CameraFeed.availableTypes()
        if types.contains(.backTelephoto) { tmp.append(.telephoto) }
        if types.contains(.backUltraWide) { tmp.append(.wide) }
        return tmp
    }
    
    static func requestMicrophoneAccess(_ block: @escaping (_: AnonPermission) -> Void) {
        let status = AVAudioSession.sharedInstance().recordPermission
        if status == .denied { block(.denied) }
        else if status == .undetermined {
            AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                DispatchQueue.main.async {
                    if !granted { block(.denied) }
                    else { block(.granted) }
                }
            })
        }
        else { block(.granted) }
    }
    
    static func requestPhotosAccess(_ block: @escaping (_: AnonPermission) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .denied || status == .restricted { block(.denied) }
        else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { auth in
                DispatchQueue.main.async {
                    if auth == .authorized { block(.granted) }
                    else { block(.denied) }
                }
            }
        }
        else { block(.granted) }
    }
    
    static func requestCameraAccess(_ block: @escaping (_: AnonPermission) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted { block(.denied) }
        else if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                DispatchQueue.main.async {
                    if !granted { block(.denied) }
                    else { block(.granted) }
                }
            })
        }
        else { block(.granted) }
    }
    
    enum AnonPermission {
        case granted
        case denied
    }
    
    enum AnonPixellateType {
        case normal
        case noise
        case bwNoise
    }
    
    struct AnonFace: Identifiable {
        var id = UUID().uuidString
        var rect: CGRect = .zero
    }
    
    struct AnonState {
        let camera: Anon.CameraFacing
        let detection: Anon.AnonDetection
        let mask: Anon.AnonMask
        let lens: Anon.CameraLens
    }
    
    private struct DetectedFace {
        let uuid: UUID
        let bounds: CGRect
    }
    
    private struct ProcessingVideo {
        let anonVideo: AnonVideo
        let fixedDate: Bool
        let location: CLLocation?
    }
    
    static private var processingVideos: [String: Anon.ProcessingVideo] = [:]
    
    static func completeProcessing(_ block: @escaping AnonSavedToPhotos) {
        self.processNextVideo { complete in
            if complete { block(true) }
            else { self.completeProcessing(block) }
        }
    }
    
    static private func processNextVideo(_ block: @escaping AnonSavedToPhotos) {
        if let processingVideo = processingVideos.first {
            processingVideo.value.anonVideo.save(cancel: false) { url in
                if let url = url {
                    Anon.saveToPhotoLibrary(image: nil, url: url, fixedDate: processingVideo.value.fixedDate, location: processingVideo.value.location) { success, localIdentifier in
                        DispatchQueue.main.async {
                            if success && localIdentifier != "" {
                                if Anon.history.count == Anon.historyCount { Anon.history.removeLast() }
                                let item = CapturedItem(localIdentifier: localIdentifier, image: nil, url: url)
                                Anon.history.insert(item, at: 0)
                            }
                            block(success)
                        }
                        processingVideo.value.anonVideo.cleanUp()
                    }
                }
                processingVideos.removeValue(forKey: processingVideo.key)
                block(false)
            }
        }
        else { block(true) }
    }
    
    let shaderView = MTKView()
    static var history: [CapturedItem] = []
    static var historyCount = 3
    var faces: [AnonFace] = []
    var widthOfPixel: Float = 0.05
    var blurRadius: Float = 20.0
    var provideViews = true
    var smoothing: CGFloat = 3.0
    var removeCount = 4
    var watermark: UIImage?
    var delegate: AnonDelegate?
    var padding: Float = 0.01
    var fillColor: UIColor?
    var pixellateType: AnonPixellateType = .noise
    var detection: AnonDetection {
        get { return currentDetection }
    }
    var effect: Anon.AnonMask {
        get { return currentEffect }
    }
    var facing: Anon.CameraFacing {
        get { return currentFacing }
    }
    var lens: Anon.CameraLens {
        get { return currentLens }
    }
    var edge: AnonEdge {
        get {
            if currentEdge == 0.0 { return .left }
            return .right
        }
        set {
            if newValue == .left { currentEdge = 0.0 }
            else { currentEdge = 1.0 }
        }
    }
    var point: CGPoint {
        get { return .zero }
        set {
            let p = newValue
            if p.x != 0 || p.y != 0 {
                let ratioPoint = CGPoint(x: p.x / shaderView.width, y: p.y / shaderView.height)
                let orientation = MotionManager.shared.orientation
                if orientation == .portrait { currentDivider = ratioPoint.x.float }
                else if orientation == .portraitUpsideDown { currentDivider = 1.0 - ratioPoint.x.float }
                else if orientation == .landscapeLeft { currentDivider = ratioPoint.y.float }
                else if orientation == .landscapeRight { currentDivider = 1.0 - ratioPoint.y.float }
            }
            else { currentDivider = 0.0 }
        }
    }
    
    enum CameraLens: Int {
        case normal
        case telephoto
        case wide
    }
    
    enum CameraFacing {
        case front
        case back
    }
    
    enum AnonMask {
        case none
        case blur
        case pixelate
    }
    
    enum AnonEdge {
        case left
        case right
    }
    
    enum AnonDetection {
        case face
        case body
        case invert
    }
    
    override init() {
        super.init()
        let context = CIContext()
        let options: [String : Any] = [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorTracking: true
        ]
        detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: options)
        
        MotionManager.shared.start()
        MotionManager.shared.onOrientationChange { (orientation) in
            var deviceRotation: UIDeviceOrientation = .landscapeLeft
            if orientation == .portrait {
                self.currentAxis = 0.0
                deviceRotation = .portrait
            }
            else if orientation == .portraitUpsideDown {
                self.currentAxis = 1.0
                deviceRotation = .portraitUpsideDown
            }
            else if orientation == .landscapeRight {
                self.currentAxis = 2.0
                deviceRotation = .landscapeRight
            }
            else { self.currentAxis = 3.0 }
            self.delegate?.rotationChange(orientation: deviceRotation)
        }
        self.detectRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, _) in
            self.detectedFaces = []
            if let results = request.results as? [VNDetectedObjectObservation] {
                for face in results {
                    let detectedFace = DetectedFace(uuid: face.uuid, bounds: face.boundingBox)
                    self.detectedFaces.append(detectedFace)
                }
                self.processFaces()
                self.isProcessing = false
            }
        })
        CameraShader.shared.arDelegate = self
    }
    
    func startRecord(audio: Bool, anonVoice: Bool) {
        var shouldRecordAudio = audio
        let status = AVAudioSession.sharedInstance().recordPermission
        if status != .granted { shouldRecordAudio = false }
        self.video = AnonVideo()
        self.video?.watermark = self.watermark
        DispatchQueue.global(qos: .background).async {
            self.video?.record(audio: shouldRecordAudio, anonVoice: anonVoice)
            CameraShader.shared.takeVideo(feed: 0, delegate: self)
        }
    }
    
    func cancelRecord() {
        CameraShader.shared.takeVideo(feed: -1, delegate: nil)
        video?.save(cancel: true, handler: { _ in
            self.video = nil
        })
    }
    
    func endRecord(fixedDate: Bool, location: CLLocation?, _ block: @escaping AnonSavedToPhotos) {
        CameraShader.shared.takeVideo(feed: -1, delegate: nil)
        if let processingVideo = video {
            Anon.processingVideos[processingVideo.uuid] = Anon.ProcessingVideo(anonVideo: processingVideo, fixedDate: fixedDate, location: location)
            processingVideo.save(cancel: false, handler: { url in
                Anon.processingVideos.removeValue(forKey: processingVideo.uuid)
                if let url = url {
                    
                    Anon.saveToPhotoLibrary(image: nil, url: url, fixedDate: fixedDate, location: location) { success, localIdentifier in
                        DispatchQueue.main.async {
                            if success && localIdentifier != "" {
                                if Anon.history.count == Anon.historyCount { Anon.history.removeLast() }
                                let item = CapturedItem(localIdentifier: localIdentifier, image: nil, url: url)
                                Anon.history.insert(item, at: 0)
                            }
                            block(success)
                        }
                        processingVideo.cleanUp()
                    }
                }
                else {
                    DispatchQueue.main.async { block(false) }
                }
            })
        }
        self.video = nil
    }
    
    func takePhoto(fixedDate: Bool, location: CLLocation?, _ block: @escaping AnonSavedToPhotos) {
        CameraShader.shared.takeImage(feed: 0, delegate: self)
        photo = AnonPhoto()
        photo?.watermark = watermark
        photo?.onImageReady({ image in
            CameraShader.shared.takeImage(feed: -1, delegate: nil)
            Anon.saveToPhotoLibrary(image: image, url: nil, fixedDate: fixedDate, location: location) { success, localIdentifier in
                DispatchQueue.main.async {
                    if success && localIdentifier != "" {
                        if Anon.history.count == Anon.historyCount { Anon.history.removeLast() }
                        let item = CapturedItem(localIdentifier: localIdentifier, image: image, url: nil)
                        Anon.history.insert(item, at: 0)
                    }
                    block(success)
                }
                self.photo = nil
            }
        })
    }
    
    func nextLens() {
        if currentFacing == .back {
            let lens = availableLens
            if lens.count > 1 {
                var n = currentLens.rawValue
                n += 1
                if n >= lens.count { n = 0 }
                let l = lens[n]
                showCamera(facing: .back, lens: l)
            }
        }
    }
    
    func showCamera(facing: CameraFacing, lens: CameraLens = .normal) {
        if fromState == nil {
            fromState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect, lens: currentLens)
        }
        currentFacing = facing
        currentLens = lens
        CameraShader.shared.stop()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.addCamera()
            self.showMask(type: self.currentEffect, detection: self.currentDetection)
        }
    }
    
    func showMask(type: AnonMask, detection: AnonDetection) {
        if currentDetection != detection {
            if fromState == nil {
                fromState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect, lens: currentLens)
            }
            if (detection == .body || detection == .invert) { currentFacing = .back }
            showCamera(facing: currentFacing)
            detectionChange = true
            currentEffect = type
            currentDetection = detection
            return
        }
        if fromState == nil {
            fromState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect, lens: currentLens)
        }
        currentEffect = type
        currentDetection = detection
        if currentFacing == .front { currentDetection = .face }
        if type == .pixelate && currentDetection == .face { CameraShader.shared.useShader(shader: FacePixelShader(), index: 0) }
        else if type == .blur && currentDetection == .face { CameraShader.shared.useShader(shader: FaceBlurShader(), index: 0) }
        else if type == .pixelate && (detection == .body || detection == .invert) { CameraShader.shared.useShader(shader: BodyPixelShader(), index: 0) }
        else if type == .blur && (detection == .body || detection == .invert) { CameraShader.shared.useShader(shader: BodyBlurShader(), index: 0) }
        else { CameraShader.shared.useShader(shader: BasicShader(), index: 0) }
        if currentDetection == .face { CameraShader.shared.sampleDelegate = self }
        else { CameraShader.shared.sampleDelegate = nil }
        if let fromState = fromState, let delegate = delegate {
            let currentState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect, lens: currentLens)
            delegate.didSwitch(from: fromState, to: currentState)
            self.fromState = nil
        }
    }
    
    // private
    private var detectedFaces: [DetectedFace] = []
    private var trackedFaces: [UUID: CGRect] = [:]
    private var currentEffect: AnonMask = .blur
    private var currentFacing: CameraFacing = .front
    private var currentDetection: AnonDetection = .face
    private var currentLens: CameraLens = .normal
    private var photo: AnonPhoto?
    private var video: AnonVideo?
    private var trackedIdleCount: [UUID: Int] = [:]
    private var detectRequest: VNDetectFaceRectanglesRequest!
    private var startCount = 0
    private var detector: CIDetector?
    private var isProcessing = false
    private var videoResolution = CGSize(width: 720, height: 1280)
    private var currentDivider: Float = 0
    private var currentAxis: Float = 0
    private var currentEdge: Float = 0
    private var detectionChange = false
    private var fromState: AnonState?
    private var sourceSize: CGSize = .zero
    
    private func convertAVFaceRect(_ b: CGRect) -> CGRect {
        if currentFacing == .front {
            return CGRect(x: (1.0 - b.minY) - b.height, y: (1.0 - b.minX) - b.width, width: b.height, height: b.width)
        }
        return CGRect(x: (1.0 - b.minY) - b.height, y: (1.0 - b.minX) - b.width, width: b.height, height: b.width)
    }
    
    private func convertFaceRect(_ b: CGRect) -> CGRect {
        if currentFacing == .front {
            return CGRect(x: (1.0 - b.minX) - b.width, y: (1.0 - b.minY) - b.height, width: b.width, height: b.height)
        }
        return CGRect(x: b.minX, y: (1.0 - b.minY) - b.height, width: b.width, height: b.height)
    }
    
    private func addCamera() {
        if Platform.hasDepthSegmentation && facing == .back && (detection == .body || detection == .invert) {
            CameraShader.shared.start(mtkViews: [shaderView], position: .back, useARFeeed: true)
        }
        else if facing == .back {
            CameraShader.shared.start(mtkViews: [shaderView], position: .back, useARFeeed: false)
        }
        else {
            if currentLens == .normal { CameraShader.shared.start(mtkViews: [shaderView], position: .front, useARFeeed: false) }
            else if currentLens == .telephoto {
                CameraShader.shared.start(mtkViews: [shaderView], position: .front, useARFeeed: false, lens: .builtInTelephotoCamera)
            }
            else if currentLens == .wide {
                CameraShader.shared.start(mtkViews: [shaderView], position: .front, useARFeeed: false, lens: .builtInUltraWideCamera)
            }
        }
    }
    
    private func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
        case .landscapeLeft:
            return .downMirrored
        case .landscapeRight:
            return .upMirrored
        default:
            return .leftMirrored
        }
    }
    
    private func rectDiff(_ a: CGRect, _ b: CGRect) -> CGFloat {
        //return a.center.distanceTo(b.center)
        let xDiff = abs(a.minX - b.minX)
        let yDiff = abs(a.minY - b.minY)
        let wDiff = abs(a.width - b.width)
        let hDiff = abs(a.height - b.height)
        return xDiff + yDiff + wDiff + hDiff
    }
    
    private func trackedMatchesDetected() {
        trackedIdleCount = [:]
    }
    
    private func trackedGreaterThanDetected() {
        if detectedFaces.count == 0 {
            for (uuid, _) in trackedFaces {
                var num = 0
                if let val = trackedIdleCount[uuid] { num = val }
                num += 1
                trackedIdleCount[uuid] = num
            }
        }
        else {
            var largestDifference: CGFloat = 0.0
            var largestUUID: UUID?
            for (uuid, rect) in trackedFaces {
                for face in detectedFaces {
                    let diff = rectDiff(rect, face.bounds)
                    if diff > largestDifference {
                        largestDifference = diff
                        largestUUID = uuid
                    }
                }
            }
            if let largestUUID = largestUUID {
                var num = 0
                if let val = trackedIdleCount[largestUUID] { num = val }
                num += 1
                trackedIdleCount[largestUUID] = num
            }
        }
        var tmp: [UUID: CGRect] = [:]
        for (uuid, rect) in trackedFaces {
            if let val = trackedIdleCount[uuid] {
                if val < removeCount { tmp[uuid] = rect }
            }
            else { tmp[uuid] = rect }
        }
        trackedFaces = tmp
    }
    
    private func trackedLessThanDetected() {
        var differences: [UUID: CGFloat] = [:]
        for face in detectedFaces {
            var smallestDiff: CGFloat = 100000000.0
            for (_, rect) in trackedFaces {
                let diff = rectDiff(rect, face.bounds)
                if diff < smallestDiff { smallestDiff = diff }
            }
            differences[face.uuid] = smallestDiff
        }
        var largestDiff: CGFloat = 0.0
        var largestUUID: UUID?
        for (uuid, diff) in differences {
            if diff > largestDiff {
                largestDiff = diff
                largestUUID = uuid
            }
        }
        if let uuid = largestUUID {
            for face in detectedFaces {
                if uuid == face.uuid {
                    trackedFaces[uuid] = face.bounds
                }
            }
        }
    }
    
    private func matchTrackedRects() -> [CGRect] {
        var rects: [CGRect] = []
        var index = 0
        var tmp: [UUID: CGRect] = [:]
        var takenUUIDs: [UUID: Bool] = [:]
        var list: [(CGFloat, UUID, CGRect)] = []
        for (uuid, rect) in trackedFaces {
            var smallestDiff: CGFloat = 100000000.0
            for face in detectedFaces {
                let diff = rectDiff(rect, face.bounds)
                if diff < smallestDiff { smallestDiff = diff }
            }
            list.append((smallestDiff, uuid, rect))
        }
        let sortedList = list.sorted { $0.0 < $1.0 }
        for (_, uuid, rect) in sortedList {
            var smallestDiff: CGFloat = 100000000.0
            var smallestUUID: UUID?
            for face in detectedFaces {
                if let _ = takenUUIDs[face.uuid] {}
                else {
                    let diff = rectDiff(rect, face.bounds)
                    if diff < smallestDiff {
                        smallestDiff = diff
                        smallestUUID = face.uuid
                    }
                }
            }
            if let smallestUUID = smallestUUID {
                var appliedSmoothing = smoothing
                if smallestDiff > 0.2 { appliedSmoothing = 1.0 }
                for face in detectedFaces {
                    if face.uuid == smallestUUID {
                        let x = rect.minX + ((face.bounds.minX - rect.minX) / appliedSmoothing)
                        let y = rect.minY + ((face.bounds.minY - rect.minY) / appliedSmoothing)
                        let w = rect.width + ((face.bounds.width - rect.width) / appliedSmoothing)
                        let h = rect.height + ((face.bounds.height - rect.height) / appliedSmoothing)
                        let r = CGRect(x: x, y: y, width: w, height: h)
                        tmp[uuid] = r
                        if index < removeCount {
                            rects.append(convertFaceRect(r))
                            index += 1
                        }
                        takenUUIDs[face.uuid] = true
                    }
                }
            }
            else {
                tmp[uuid] = rect
                if index < removeCount {
                    rects.append(convertFaceRect(rect))
                    index += 1
                }
            }
        }
        trackedFaces = tmp
        return rects
    }
    
    private func updateShaders(rects: [CGRect]) {
        var scale: Float = 1.0
        if trackedFaces.count != 0 {
            var size: CGFloat = 0
            for (_, rect) in trackedFaces {
                let area = (rect.width * rect.width) + (rect.height * rect.height)
                size += area
            }
            let avg = size / (trackedFaces.count.cgFloat)
            let pos = Curve.cubic.easeOut(avg.float)
            scale = 4 * pos
        }
        if let faceShader = CameraShader.shared.shader(at: 0) as? FaceShader {
            faceShader.widthOfPixel = widthOfPixel
            faceShader.padding = padding
            faceShader.faces = rects
            faceShader.axis = currentAxis
            faceShader.divider = currentDivider
            faceShader.edge = currentEdge
            faceShader.scale = scale
            faceShader.color = fillColor
            if pixellateType == .normal { faceShader.pixelType = 0 }
            else if pixellateType == .noise { faceShader.pixelType = 1 }
            else if pixellateType == .bwNoise { faceShader.pixelType = 2 }
        }
        if let bodyShader = CameraShader.shared.shader(at: 0) as? BodyShader {
            bodyShader.widthOfPixel = widthOfPixel
            bodyShader.axis = currentAxis
            bodyShader.divider = currentDivider
            bodyShader.edge = currentEdge
            bodyShader.padding = padding
            bodyShader.color = fillColor
            if pixellateType == .normal { bodyShader.pixelType = 0 }
            else if pixellateType == .noise { bodyShader.pixelType = 1 }
            else if pixellateType == .bwNoise { bodyShader.pixelType = 2 }
            if currentDetection == .body { bodyShader.invert = 0.0 }
            else { bodyShader.invert = 1.0 }
        }
        if let faceBlurShader = CameraShader.shared.shader(at: 0) as? FaceBlurShader {
            faceBlurShader.blurRadius = blurRadius
        }
        if let bodyBlurShader = CameraShader.shared.shader(at: 0) as? BodyBlurShader {
            bodyBlurShader.blurRadius = blurRadius
        }
    }
    
    private func detectFaces(_ sampleBuffer: CMSampleBuffer) {
        isProcessing = true
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
            let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
            if cameraIntrinsicData != nil {
                requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
            }
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .right, options: requestHandlerOptions)
            try? imageRequestHandler.perform([detectRequest])
        }
    }
    
    private func convertViewRect(_ box: CGRect) -> CGRect {
        let b = convertFaceRect(box)
        var aspectScale: CGFloat = 1.0
        if sourceSize.width > 0 && sourceSize.height > 0 {
            aspectScale = (shaderView.width / shaderView.height) / (sourceSize.width / sourceSize.height)
        }
        let h = shaderView.height * aspectScale
        let y = (h - shaderView.height) / 2
        return CGRect(x: (b.minX * shaderView.width) + ((b.width * shaderView.width) / 2), y: ((b.minY * h) - y) + ((b.height * h) / 2), width: b.width * shaderView.width, height: b.height * h)
    }
    
    private func processFaces() {
        if trackedFaces.count == detectedFaces.count { trackedMatchesDetected() }
        else if trackedFaces.count > detectedFaces.count { trackedGreaterThanDetected() }
        else if trackedFaces.count < detectedFaces.count { trackedLessThanDetected() }
        let rects = matchTrackedRects()
        updateShaders(rects: rects)
        if provideViews {
            DispatchQueue.main.async {
                var faceTmp: [AnonFace] = []
                for trackedFace in self.trackedFaces {
                    faceTmp.append(AnonFace(id: trackedFace.key.uuidString, rect: self.convertViewRect(trackedFace.value)))
                }
                self.faces = faceTmp
                self.delegate?.updated(faces: self.faces)
            }
        }
    }
    
    private static func saveToPhotoLibrary(image: UIImage?, url: URL?, fixedDate: Bool, location: CLLocation?, completion: @escaping AnonSavedToPhotoLibrary) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Anonymous Camera")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        var localIdentifier = ""
        if let assetCollection = collection.firstObject {
            PHPhotoLibrary.shared().performChanges({
                var asset: PHAssetChangeRequest?
                if let image = image { asset = PHAssetChangeRequest.creationRequestForAsset(from: image) }
                if let url = url { asset = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }
                if let asset = asset, let placeholder = asset.placeholderForCreatedAsset {
                    localIdentifier = placeholder.localIdentifier
                    var date = Date()
                    if fixedDate { date = Date(timeIntervalSince1970: 0) }
                    asset.creationDate = date
                    if let location = location { asset.location = location }
                    if let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection) {
                        let enumeration: NSArray = [placeholder]
                        albumChangeRequest.addAssets(enumeration)
                    }
                }
            }) { (success, error) in
                completion(success, localIdentifier)
            }
        }
        else {
            Anon.createAnonCameraAlbum(image: image, url: url, fixedDate: fixedDate, location: location, completion: completion)
        }
    }
    
    private static func createAnonCameraAlbum(image: UIImage?, url: URL?, fixedDate: Bool, location: CLLocation?, completion: @escaping AnonSavedToPhotoLibrary) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Anonymous Camera")
        }) { saved, error in
            Anon.saveToPhotoLibrary(image: image, url: url, fixedDate: fixedDate, location: location, completion: completion)
        }
    }
    
}

extension Anon: CameraShaderSampleDelegate {
    func capturedFaces(_ rects: [CGRect]) {
        if startCount < 5 {}
        else if (detection == .face || facing == .front) {
            if !Platform.hasDepthSegmentation {
                self.detectedFaces = []
                for rect in rects {
                    let detectedFace = DetectedFace(uuid: UUID(), bounds: convertAVFaceRect(rect))
                    self.detectedFaces.append(detectedFace)
                }
                self.processFaces()
                self.isProcessing = false
            }
        }
    }
    func captureOutput(_ output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection, skip: Bool) {
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            sourceSize = CGSize(width: height, height: width)
        }
        if startCount < 5 { startCount += 1 }
        else if (detection == .face || facing == .front) {
            if Platform.hasDepthSegmentation { self.detectFaces(sampleBuffer) }
        }
    }
}

extension Anon: CameraShaderImageDelegate {
    func didDrawImage(drawable: CAMetalDrawable) {
        photo?.addAnonBuffer(currentDrawable: drawable)
    }
}

extension Anon: CameraShaderVideoDelegate {
    func didDrawFrame(texture: MTLTexture, timestamp: Double) {
        video?.addFrame(texture: texture, time: timestamp)
    }
}

extension Anon: CameraShaderARDelegate {
    func willRenderAR() {
       updateShaders(rects: [])
    }
}

