//
//  ACScene.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 26/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI
import StoreKit
import UIKit
import SwiftyUserDefaults


final public class ACScene : ObservableObject {
    @Published public var sceneIsActive : Bool = false
    
    @Published public var productsAvailable : Bool = false
//    @Published public var product : SKProduct?
    @Published public var proPurchased : Bool = false

    
    @Published public var deviceOrientation : UIDeviceOrientation = UIDevice.current.orientation {
        didSet {
            if !(deviceOrientation == .faceDown || deviceOrientation == .faceUp || deviceOrientation == .portraitUpsideDown || deviceOrientation == .unknown) {
                if oldValue.isLandscape {
                    devicePreviousOrientationWasLandscape = true
                } else {
                    devicePreviousOrientationWasLandscape = false
                }
                
                if !deviceOrientation.isLandscape {
                    ACAnonymisation.shared.interviewModeConfiguration = .off
                }
                
                if deviceOrientation == .landscapeLeft {
                    deviceRotationAngle = Angle(degrees: 90)
                    deviceLandscapeRotationAngle = Angle(degrees: 90)
                } else if deviceOrientation == .landscapeRight {
                    deviceRotationAngle = Angle(degrees: -90)
                    deviceLandscapeRotationAngle = Angle(degrees: -90)
                } else {
                    deviceRotationAngle = Angle(degrees: 0)
                }
            }
        }
    }
    @Published public var deviceRotationAngle : Angle = Angle(degrees: 0)
    @Published public var deviceLandscapeRotationAngle : Angle = Angle(degrees: 90)
    @Published public var devicePreviousOrientationWasLandscape : Bool = false
    
    @Published public var isVideoRecording : Bool = false
    
    @Published public var internetConnection : Bool = true

    @Published public var interviewModeAvailable : Bool = Defaults[\.interviewMode]! {
        didSet {
            Defaults[\.interviewMode]! = interviewModeAvailable
        }
    }
    @Published public var interviewModeControlIsHoveringOverClose : Bool = false
    @Published public var interviewModeControlIsBeingTouched : Bool = false
    
    @Published public var isDraggingBottomSheet : Bool = false  {
        
        didSet {
            if !bottomSheetIsOpen && !isDraggingBottomSheet {
                Anon.resume()
            } else {
                Anon.pause()
            }
            
        }
        
    }
    
    @Published public var bottomSheetIsOpen : Bool = false {
        
        didSet {
            if bottomSheetIsOpen {
                Anon.pause()
            } else {
                Anon.resume()
            }
        }
        
    }
    
    @Published public var showHUD : Bool = false
    @Published public var hudLoading : Bool = false
    @Published public var hudTint : UIColor = .black
    @Published public var hudString : String = "Placeholder"
    @Published public var hudIcon : UIImage?
    
    static var shared = ACScene()
}
