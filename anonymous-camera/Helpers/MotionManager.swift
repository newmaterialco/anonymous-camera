//
//  MotionManager.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import Foundation
import SwifterSwift
import CoreMotion

typealias MotionManagerDataHandler = (_: Double, _: Double, _: Double) -> Void
typealias MotionManagerOrientationHandler = (_: UIDeviceOrientation) -> Void

class MotionManager {
    
    var orientation: UIDeviceOrientation = .unknown
    private let motionManager = CMMotionManager()
    private var dataHandler: MotionManagerDataHandler?
    private var orientationHandler: MotionManagerOrientationHandler?
    private var nextOrientation: UIDeviceOrientation = .unknown
    private var nextCount = 0
    
    fileprivate static var instance: MotionManager?
    static var shared: MotionManager {
        if instance == nil {
            instance = MotionManager()
        }
        return instance!
    }
    
    var isAvailable: Bool {
        return motionManager.isDeviceMotionAvailable
    }
    
    func onData(_ block: @escaping MotionManagerDataHandler) {
        dataHandler = block
    }
    
    func onOrientationChange(_ block: @escaping MotionManagerOrientationHandler) {
        orientationHandler = block
    }
    
    func start() {
        if isAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let data = data {
                    var currentOrientation: UIDeviceOrientation = .unknown
                    let yxAtan = (atan2(data.acceleration.y, data.acceleration.x)) * (180.0 / Double.pi)
                    let zyAtan = (atan2(data.acceleration.z, data.acceleration.y)) * (180.0 / Double.pi)
                    let zxAtan = (atan2(data.acceleration.z, data.acceleration.x)) * (180.0 / Double.pi)
                    if zyAtan > -93 && zyAtan < -87 && zxAtan > -93 && zxAtan < -87 { currentOrientation = .unknown }
                    else if zyAtan < 93 && zyAtan > 87 && zxAtan < 93 && zxAtan > 87 { currentOrientation = .unknown }
                    else if (fabs(yxAtan) <= 45) { currentOrientation = .landscapeRight }
                    else if ((fabs(yxAtan) > 45) && (fabs(yxAtan) < 135)) {
                        if (yxAtan > 0) { currentOrientation = .portraitUpsideDown }
                        else { currentOrientation = .portrait }
                    }
                    else { currentOrientation = .landscapeLeft }
                    if currentOrientation != .unknown && self.orientation == .unknown {
                        self.orientation = currentOrientation
                        DispatchQueue.main.async { self.orientationHandler?(self.orientation) }
                    }
                    else if currentOrientation != self.orientation && currentOrientation != .unknown {
                        if currentOrientation != self.nextOrientation {
                            self.nextOrientation = currentOrientation
                            self.nextCount = 0
                        }
                        else {
                            self.nextCount += 1
                            if self.nextCount >= 3 {
                                self.orientation = currentOrientation
                                DispatchQueue.main.async { self.orientationHandler?(self.orientation) }
                            }
                        }
                    }
                }
            }
            motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                if let data = data {
                    let quat = data.attitude.quaternion
                    var pitch = atan2(2 * quat.x * quat.w - 2 * quat.y * quat.z, 1 - 2 * quat.x * quat.x - 2 * quat.z * quat.z).radiansToDegrees
                    pitch -= 90
                    let roll = atan2(2 * quat.y * quat.w - 2 * quat.x * quat.z, 1 - 2 * quat.y * quat.y - 2 * quat.z * quat.z).radiansToDegrees
                    let yaw = asin(2 * quat.x * quat.y + 2 * quat.z * quat.w).radiansToDegrees
                    DispatchQueue.main.async { self.dataHandler?(pitch, -roll, yaw) }
                }
            }
        }
        else {
            NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
    }
    
    @objc private func rotated() {
        let rotation = UIDevice.current.orientation
        if rotation == .portrait { orientation = .portrait }
        else if rotation == .portraitUpsideDown { orientation = .portraitUpsideDown }
        else if rotation == .landscapeLeft { orientation = .landscapeLeft }
        else if rotation == .landscapeRight { orientation = .landscapeRight }
        orientationHandler?(orientation)
    }
    
}
