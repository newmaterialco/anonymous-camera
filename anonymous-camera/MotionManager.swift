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

class MotionManager {
    
    private let motionManager = CMMotionManager()
    
    fileprivate static var instance: MotionManager?
    static var shared: MotionManager {
        if instance == nil {
            instance = MotionManager ()
        }
        return instance!
    }
    
    func start(_ block: @escaping MotionManagerDataHandler) {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                if let data = data {
                    let quat = data.attitude.quaternion
                    var pitch = atan2(2 * quat.x * quat.w - 2 * quat.y * quat.z, 1 - 2 * quat.x * quat.x - 2 * quat.z * quat.z).radiansToDegrees
                    pitch -= 90
                    //if pitch < -10 { pitch = -10 }
                    //else if pitch > 10 { pitch = 10 }
                    let roll = atan2(2 * quat.y * quat.w - 2 * quat.x * quat.z, 1 - 2 * quat.y * quat.y - 2 * quat.z * quat.z).radiansToDegrees
                    let yaw = asin(2 * quat.x * quat.y + 2 * quat.z * quat.w).radiansToDegrees
                    DispatchQueue.main.async {
                        block(pitch, -roll, yaw)
                        //block(pitch, roll, -yaw)
                    }
                }
            }
        }
    }
    
}
