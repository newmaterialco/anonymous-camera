//
//  AnonVideo.swift
//  faceblur
//
//  Created by Alisdair Mills on 03/10/2019.
//  Copyright © 2019 amills. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation
import VideoToolbox
import Accelerate

typealias AnonVideoComplete = (_ : URL?) -> Void

class AnonVideo: NSObject {
    
    var watermark: UIImage?
    var outputSize = CGSize(width: 720, height: 1280)
    let uuid = UUID().uuidString
    
    private var isRecording = false
    private var recordingStartTime = TimeInterval(0)
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    private var videoURL: URL?
    private var audioURL: URL?
    private var outputURL: URL?
    private var anonAudioURL: URL?
    private var recordingDuration = 0.0
    private var tmpHandler: AnonVideoComplete?
    private var lastFrameTime = 0.0
    private var landscapeLeftDuration = 0.0
    private var landscapeRightDuration = 0.0
    private var portraitDuration = 0.0
    
    func cleanUp() {
        if let dest = videoURL, let audioDest = audioURL, let outputDest = outputURL {
            if FileManager.default.fileExists(atPath: dest.absoluteString.replacingOccurrences(of: "file://", with: "")) {
                do { try FileManager.default.removeItem(at: dest) }
                catch {}
            }
            if FileManager.default.fileExists(atPath: audioDest.absoluteString.replacingOccurrences(of: "file://", with: "")) {
                do { try FileManager.default.removeItem(at: audioDest) }
                catch {}
            }
            if FileManager.default.fileExists(atPath: outputDest.absoluteString.replacingOccurrences(of: "file://", with: "")) {
                do { try FileManager.default.removeItem(at: outputDest) }
                catch {}
            }
        }
        if let anonAudioURL = anonAudioURL {
            if FileManager.default.fileExists(atPath: anonAudioURL.absoluteString.replacingOccurrences(of: "file://", with: "")) {
                do { try FileManager.default.removeItem(at: anonAudioURL) }
                catch {}
            }
        }
    }
    
    func record(audio: Bool, anonVoice: Bool) {
        let tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory())
        if let dest = URL(string: "\(tmpDirURL.absoluteString)\(uuid)_video.m4v"), let audioDest = URL(string: "\(tmpDirURL.absoluteString)\(uuid)_audio.caf"), let outputDest = URL(string: "\(tmpDirURL.absoluteString)\(uuid)_tmp.m4v") {
            videoURL = dest
            outputURL = outputDest
            do { assetWriter = try AVAssetWriter(outputURL: dest, fileType: AVFileType.m4v) }
            catch {}
            if let writer = assetWriter {
                let outputSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: outputSize.width, AVVideoHeightKey: outputSize.height]
                assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
                assetWriterVideoInput?.expectsMediaDataInRealTime = true
                recordingSession = AVAudioSession.sharedInstance()
                try? recordingSession?.setCategory(.playAndRecord, mode: .default)
                try? recordingSession?.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderBitRateKey: 64000,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                if audio {
                    audioURL = audioDest
                    if anonVoice {
                        anonAudioURL = URL(string: "\(tmpDirURL.absoluteString)\(uuid)_anon.caf")
                    }
                    audioRecorder = try? AVAudioRecorder(url: audioDest, settings: settings)
                    audioRecorder?.delegate = self
                    audioRecorder?.record()
                    let sourcePixelBufferAttributes: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: outputSize.width, kCVPixelBufferHeightKey as String: outputSize.height]
                    if let input = assetWriterVideoInput {
                        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
                        writer.add(input)
                    }
                }
            }
        }
    }
    
    func addFrame(texture: MTLTexture, time: Double) {
        if !isRecording {
            recordingStartTime = CACurrentMediaTime()
            isRecording = true
            if let writer = assetWriter {
                if writer.status != .writing {
                    writer.startWriting()
                    writer.startSession(atSourceTime: CMTime.zero)
                    lastFrameTime = time
                }
            }
        }
        if time < lastFrameTime { return }
        let timeSinceLast = time - lastFrameTime
        let orientation = UIDevice.current.orientation
        if orientation == .landscapeLeft { landscapeLeftDuration += timeSinceLast }
        else if orientation == .landscapeRight { landscapeRightDuration += timeSinceLast }
        else { portraitDuration += timeSinceLast }
        lastFrameTime = time
        if let input = self.assetWriterVideoInput {
            while !input.isReadyForMoreMediaData {}
            if let bufferInput = self.assetWriterPixelBufferInput {
                if let pixelBufferPool = bufferInput.pixelBufferPool {
                    var maybePixelBuffer: CVPixelBuffer? = nil
                    let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
                    if status != kCVReturnSuccess {}
                    else if let pixelBuffer = maybePixelBuffer {
                        CVPixelBufferLockBaseAddress(pixelBuffer, [])
                        if let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer) {
                            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
                            let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
                            texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
                            let frameTime = CACurrentMediaTime() - self.recordingStartTime
                            recordingDuration = frameTime
                            let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 1000)
                            bufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
                        }
                        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                    }
                }
            }
        }
    }
    
    func save(cancel: Bool, handler: @escaping AnonVideoComplete) {
        if isRecording {
            isRecording = false
            if cancel { cancelRecording(handler: handler) }
            else if let _ = audioRecorder { combineVideoAndAudio(handler: handler) }
            else { handler(nil) }
        }
    }
    
    private func combineVideoAndAudio(handler: @escaping AnonVideoComplete) {
        if let input = assetWriterVideoInput, let writer = assetWriter {
            input.markAsFinished()
            writer.finishWriting {
                self.assetWriterPixelBufferInput = nil
                self.assetWriterVideoInput = nil
                self.assetWriter = nil
                if let audioRecorder = self.audioRecorder {
                    self.tmpHandler = handler
                    audioRecorder.stop()
                }
                else { self.createVideo(handler: handler) }
            }
        }
    }
    
    private func createVideo(handler: @escaping AnonVideoComplete) {
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: CMTimeValue(1), timescale: CMTimeScale(30))
        videoComposition.renderSize = CGSize(width: outputSize.width, height: outputSize.height)
        if landscapeLeftDuration > portraitDuration || landscapeRightDuration > portraitDuration {
            videoComposition.renderSize = CGSize(width: outputSize.height, height: outputSize.width)
        }
        var videoAsset: AVAsset?
        var audioAsset: AVAsset?
        if let url = videoURL { videoAsset = AVAsset(url: url) }
        if let url = audioURL, let _ = audioRecorder { audioAsset = AVAsset(url: url) }
        if let url = anonAudioURL, let _ = audioRecorder  { audioAsset = AVAsset(url: url) }
        if let vAsset = videoAsset {
            if let details = videoDetails(asset: vAsset, composition: composition) {
                let assetTrack = details.0
                let compositionTrackId = details.1
                let compositionTrack = details.2
                let startTime = CMTime(value: CMTimeValue(10), timescale: CMTimeScale(30))
                let compositionTrackPassThroughTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: assetTrack.timeRange.duration - startTime)
                let assetTrackRange = CMTimeRangeMake(start: startTime, duration: assetTrack.timeRange.duration - startTime)
                try? compositionTrack.insertTimeRange(assetTrackRange, of: assetTrack, at: CMTime.zero)
                if let audioAsset = audioAsset, let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                    if let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: composition.unusedTrackID()) {
                        try? audioCompositionTrack.insertTimeRange(assetTrackRange, of: audioTrack, at: CMTime.zero)
                    }
                }
                var compositionTrackPassThroughInstruction = AVMutableVideoCompositionInstruction.passThrough(trackId: compositionTrackId, timeRange: compositionTrackPassThroughTimeRange, transform: nil)
                
                if landscapeRightDuration > portraitDuration {
                    var transform = CGAffineTransform(translationX: outputSize.height, y: 0)
                    transform = transform.rotated(by: 90.degreesToRadians.cgFloat)
                    compositionTrackPassThroughInstruction = AVMutableVideoCompositionInstruction.passThrough(trackId: compositionTrackId, timeRange: compositionTrackPassThroughTimeRange, transform: transform)
                }
                else if landscapeLeftDuration > portraitDuration {
                    var transform = CGAffineTransform(translationX: 0, y: outputSize.width)
                    transform = transform.rotated(by: -90.degreesToRadians.cgFloat)
                    compositionTrackPassThroughInstruction = AVMutableVideoCompositionInstruction.passThrough(trackId: compositionTrackId, timeRange: compositionTrackPassThroughTimeRange, transform: transform)
                }
                videoComposition.instructions.append(compositionTrackPassThroughInstruction)
                
                if let watermark = watermark {
                    let aLayer = CALayer()
                    aLayer.contents = watermark.cgImage
                    aLayer.frame = CGRect(x: videoComposition.renderSize.width - 20 - watermark.size.width, y: 20, width: watermark.size.width, height: watermark.size.height)
                    let parentLayer = CALayer()
                    parentLayer.frame = CGRect(x: 0, y: 0, width: videoComposition.renderSize.width, height: videoComposition.renderSize.height)
                    let videoLayer = CALayer()
                    videoLayer.frame = CGRect(x: 0, y: 0, width: videoComposition.renderSize.width, height: videoComposition.renderSize.height)
                    parentLayer.addSublayer(videoLayer)
                    videoLayer.addSublayer(aLayer)
                    let animationVideoTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
                    videoComposition.animationTool = animationVideoTool
                }
                
                if let dest = self.outputURL {
                    if let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
                        exporter.outputFileType = AVFileType.mp4
                        exporter.shouldOptimizeForNetworkUse = false
                        exporter.videoComposition = videoComposition
                        exporter.outputURL = dest
                        exporter.exportAsynchronously {
                            DispatchQueue.main.async { handler(self.outputURL) }
                        }
                    }
                }
            }
        }
    }
    
    private func cancelRecording(handler: @escaping AnonVideoComplete) {
        if let audioRecorder = audioRecorder {
            audioRecorder.delegate = nil
            audioRecorder.stop()
            self.audioRecorder = nil
            recordingSession = nil
        }
        if let input = assetWriterVideoInput, let writer = assetWriter {
            input.markAsFinished()
            writer.finishWriting {
                self.assetWriterPixelBufferInput = nil
                self.assetWriterVideoInput = nil
                self.assetWriter = nil
                self.cleanUp()
            }
        }
        DispatchQueue.main.async { handler(nil) }
    }
    
    private func videoDetails(asset: AVAsset, composition: AVMutableComposition) -> (AVAssetTrack, CMPersistentTrackID, AVMutableCompositionTrack)? {
        if let assetTrack = asset.tracks(withMediaType: .video).first {
            let compositionTrackId = composition.unusedTrackID()
            if let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: compositionTrackId) {
                return(assetTrack, compositionTrackId, compositionTrack)
            }
        }
        return nil
    }
    
    private func anonymizeAudio() {
        if let audioURL = audioURL, let anonAudioURL = anonAudioURL, let sourceFile = try? AVAudioFile(forReading: audioURL) {
            let format = sourceFile.processingFormat
            let engine = AVAudioEngine()
            let player1 = AVAudioPlayerNode()
            let player2 = AVAudioPlayerNode()
            let pitch1 = AVAudioUnitTimePitch()
            pitch1.pitch = 250
            let pitch2 = AVAudioUnitTimePitch()
            pitch2.pitch = -250
            engine.attach(player1)
            engine.attach(pitch1)
            engine.attach(player2)
            engine.attach(pitch2)
            engine.connect(player1, to: pitch1, format: format)
            engine.connect(pitch1, to: engine.mainMixerNode, format: format)
            engine.connect(player2, to: pitch2, format: format)
            engine.connect(pitch2, to: engine.mainMixerNode, format: format)
            player1.scheduleFile(sourceFile, at: nil)
            player2.scheduleFile(sourceFile, at: nil)
            let maxFrames: AVAudioFrameCount = 4096
            try? engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxFrames)
            try? engine.start()
            player1.play()
            player2.play()
            if let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount) {
                let outputFile = try? AVAudioFile(forWriting: anonAudioURL, settings: sourceFile.fileFormat.settings)
                while engine.manualRenderingSampleTime < sourceFile.length {
                    let frameCount = sourceFile.length - engine.manualRenderingSampleTime
                    let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)
                    let status = try? engine.renderOffline(framesToRender, to: buffer)
                    if status == .success {
                        try? outputFile?.write(from: buffer)
                    }
                }
            }
            player1.stop()
            player2.stop()
            engine.stop()
            if let handler = tmpHandler {
                createVideo(handler: handler)
            }
        }
        else {
            if let handler = tmpHandler {
                createVideo(handler: handler)
            }
        }
    }
    
}

extension AnonVideo: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if let handler = tmpHandler {
            if let _ = anonAudioURL { anonymizeAudio() }
            else { createVideo(handler: handler) }
        }
        audioRecorder = nil
        recordingSession = nil
        tmpHandler = nil
    }
}

extension AVMutableVideoCompositionInstruction {
    static func passThrough(trackId: CMPersistentTrackID, timeRange: CMTimeRange, transform: CGAffineTransform?) -> AVMutableVideoCompositionInstruction {
        let layerInstruction = AVMutableVideoCompositionLayerInstruction()
        layerInstruction.trackID = trackId
        if let t = transform {
            layerInstruction.setTransform(t, at: timeRange.start)
        }
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        instruction.layerInstructions = [layerInstruction]
        return instruction
    }
}
