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

protocol AnonDelegate {
    func rotationChange(orientation: UIDeviceOrientation)
    func didSwitch(from: Anon.AnonState, to: Anon.AnonState)
    func updated(faces: [Anon.AnonFace])
}

class Anon: NSObject {
    
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
    
    struct AnonFace: Identifiable {
        var id = UUID().uuidString
        var rect: CGRect = .zero
    }
    
    struct AnonState {
        let camera: Anon.CameraFacing
        let detection: Anon.AnonDetection
        let mask: Anon.AnonMask
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
                    Anon.saveToPhotoLibrary(image: nil, url: url, fixedDate: processingVideo.value.fixedDate, location: processingVideo.value.location) { success in
                        DispatchQueue.main.async { block(success) }
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
    var faces: [AnonFace] = []
    var widthOfPixel: Float = 0.05
    var blurRadius: Float = 20.0
    var provideViews = true
    var smoothing: CGFloat = 3.0
    var removeCount = 4
    var watermark: UIImage?
    var delegate: AnonDelegate?
    var padding: Float = 0.01
    var detection: AnonDetection {
        get { return currentDetection }
    }
    var effect: Anon.AnonMask {
        get { return currentEffect }
    }
    var facing: Anon.CameraFacing {
        get { return currentFacing }
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
                let positionInImage = CGPoint(x: -shaderView.x + p.x, y: -shaderView.y + p.y)
                let ratioPoint = CGPoint(x: positionInImage.x / shaderView.width, y: positionInImage.y / shaderView.height)
                let orientation = UIDevice.current.orientation
                if orientation == .portrait { currentDivider = ratioPoint.x.float }
                else if orientation == .portraitUpsideDown { currentDivider = 1.0 - ratioPoint.x.float }
                else if orientation == .landscapeLeft { currentDivider = ratioPoint.y.float }
                else if orientation == .landscapeRight { currentDivider = 1.0 - ratioPoint.y.float }
            }
            else { currentDivider = 0.0 }
        }
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
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
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
        self.video?.outputSize = CameraShader.shared.renderResolution
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
                    Anon.saveToPhotoLibrary(image: nil, url: url, fixedDate: fixedDate, location: location) { success in
                        DispatchQueue.main.async { block(success) }
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
        captureHandler = block
        photo = AnonPhoto()
        photo?.watermark = watermark
        photo?.onImageReady({ image in
            CameraShader.shared.takeImage(feed: -1, delegate: nil)
            Anon.saveToPhotoLibrary(image: image, url: nil, fixedDate: fixedDate, location: location) { success in
                DispatchQueue.main.async { self.captureHandler?(success) }
                self.captureHandler = nil
                self.photo = nil
            }
        })
    }
    
    func showCamera(facing: CameraFacing) {
        if fromState == nil {
            fromState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect)
        }
        currentFacing = facing
        CameraShader.shared.stop()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.addCamera()
            self.showMask(type: self.currentEffect, detection: self.currentDetection)
        }
    }
    
    func showMask(type: AnonMask, detection: AnonDetection) {
        if currentDetection != detection {
            if fromState == nil {
                fromState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect)
            }
            if (detection == .body || detection == .invert) { currentFacing = .back }
            showCamera(facing: currentFacing)
            detectionChange = true
            currentEffect = type
            currentDetection = detection
            return
        }
        if fromState == nil {
            fromState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect)
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
            let currentState = AnonState(camera: currentFacing, detection: currentDetection, mask: currentEffect)
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
    private var photo: AnonPhoto?
    private var video: AnonVideo?
    private var captureHandler: AnonSavedToPhotos?
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
    
    @objc private func rotated() {
        delegate?.rotationChange(orientation: UIDevice.current.orientation)
        if UIDevice.current.orientation == .portrait { currentAxis = 0.0 }
        else if UIDevice.current.orientation == .portraitUpsideDown { currentAxis = 1.0 }
        else if UIDevice.current.orientation == .landscapeRight { currentAxis = 2.0 }
        else { currentAxis = 3.0 }
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
            CameraShader.shared.start(mtkViews: [shaderView], position: .front, useARFeeed: false)
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
    
    private func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    private func rectDiff(_ a: CGRect, _ b: CGRect) -> CGFloat {
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
        for (uuid, rect) in trackedFaces {
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
        }
        if let bodyShader = CameraShader.shared.shader(at: 0) as? BodyShader {
            bodyShader.widthOfPixel = widthOfPixel
            bodyShader.axis = currentAxis
            bodyShader.divider = currentDivider
            bodyShader.edge = currentEdge
            bodyShader.padding = padding;
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
    
    private func detectFacesCoreImage(_ sampleBuffer: CMSampleBuffer) {
        let orientation = UIDevice.current.orientation
        var imageOrientation: CGImagePropertyOrientation = .right
        if orientation == .portraitUpsideDown { imageOrientation = .left }
        else if orientation == .landscapeLeft { imageOrientation = .down }
        else if orientation == .landscapeRight { imageOrientation = .up }
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: cvImageBuffer).oriented(forExifOrientation: Int32(imageOrientation.rawValue))
        let cvImageHeight = CGFloat(CVPixelBufferGetHeight(cvImageBuffer))
        let cvImageWidth = CGFloat(CVPixelBufferGetWidth(cvImageBuffer))
        if let detect = detector {
            let faceAreas = detect.features(in: ciImage)
            let size = CGSize(width: cvImageHeight, height: cvImageWidth)
            detectedFaces = []
            for face in faceAreas {
                var x = face.bounds.minX / size.width
                var y = face.bounds.minY / size.height
                var w = face.bounds.width / size.width
                var h = face.bounds.height / size.height
                var bounds = CGRect(x: x, y: y, width: w, height: h)
                if orientation == .portraitUpsideDown {
                    bounds = CGRect(x: (1.0 - x) - w, y: (1.0 - y) - h, width: w, height: h)
                }
                else if orientation == .landscapeRight || orientation == .landscapeLeft {
                    x = face.bounds.minY / size.width
                    y = face.bounds.minX / size.height
                    w = face.bounds.height / size.width
                    h = face.bounds.width / size.height
                    bounds = CGRect(x: x, y: (1.0 - y) - h, width: w, height: h)
                    if orientation == .landscapeLeft {
                        bounds = CGRect(x: (1.0 - x) - w, y: y, width: w, height: h)
                    }
                }
                let detectedFace = DetectedFace(uuid: UUID(), bounds: bounds)
                detectedFaces.append(detectedFace)
            }
        }
        processFaces()
    }
    
    private func convertViewRect(_ box: CGRect) -> CGRect {
        let b = convertFaceRect(box)
        return CGRect(x: b.minX * shaderView.width, y: b.minY * shaderView.height, width: b.width * shaderView.width, height: b.height * shaderView.height)
    }
    
    private func processFaces() {
        if trackedFaces.count == detectedFaces.count { trackedMatchesDetected() }
        else if trackedFaces.count > detectedFaces.count { trackedGreaterThanDetected() }
        else if trackedFaces.count < detectedFaces.count { trackedLessThanDetected() }
        let rects = matchTrackedRects()
        updateShaders(rects: rects)
        if provideViews {
            DispatchQueue.main.async {
                let orientation = UIDevice.current.orientation
                var faceTmp: [AnonFace] = []
                for trackedFace in self.trackedFaces {
                    let rect = trackedFace.value
                    let b = self.convertFaceRect(rect)
                    var r = self.convertViewRect(b)
                    if orientation.isLandscape {
                        r = CGRect(x: r.minX - ((r.height - r.width) / 2), y: r.minY - ((r.width - r.height) / 2), width: r.height, height: r.width)
                    }
                    faceTmp.append(AnonFace(id: trackedFace.key.uuidString, rect: r))
                }
                self.faces = faceTmp
                self.delegate?.updated(faces: self.faces)
            }
        }
    }
    
    private static func saveToPhotoLibrary(image: UIImage?, url: URL?, fixedDate: Bool, location: CLLocation?, completion: @escaping AnonSavedToPhotos) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Anonymous Camera")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let assetCollection = collection.firstObject {
            PHPhotoLibrary.shared().performChanges({
                var asset: PHAssetChangeRequest?
                if let image = image { asset = PHAssetChangeRequest.creationRequestForAsset(from: image) }
                if let url = url { asset = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }
                if let asset = asset, let placeholder = asset.placeholderForCreatedAsset {
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
                completion(success)
            }
        }
        else {
            Anon.createAnonCameraAlbum(image: image, url: url, fixedDate: fixedDate, location: location) { _ in
            }
        }
    }
    
    private static func createAnonCameraAlbum(image: UIImage?, url: URL?, fixedDate: Bool, location: CLLocation?, completion: @escaping AnonSavedToPhotos) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Anonymous Camera")
        }) { saved, error in
            Anon.saveToPhotoLibrary(image: image, url: url, fixedDate: fixedDate, location: location) { _ in
            }
        }
    }
    
}

extension Anon: CameraShaderSampleDelegate {
    func captureOutput(_ output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection, skip: Bool) {
        if startCount < 5 { startCount += 1 }
        else if (detection == .face || facing == .front) {
            if Platform.hasDepthSegmentation { self.detectFaces(sampleBuffer) }
            else { self.detectFacesCoreImage(sampleBuffer) }
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

