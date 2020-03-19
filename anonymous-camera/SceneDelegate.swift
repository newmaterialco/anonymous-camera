//
//  SceneDelegate.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var sceneInformation = ACScene.shared
    var anonymisation = ACAnonymisation.shared

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = ContentView()
            .environmentObject(sceneInformation)
            .environmentObject(anonymisation)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = false
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = true
    }

    func sceneWillResignActive(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = false

    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}

final public class ACScene : ObservableObject {
    @Published public var sceneIsActive : Bool = false
    
    @Published public var deviceOrientation : UIDeviceOrientation = UIDevice.current.orientation {
        didSet {
            
            if oldValue.isLandscape {
                devicePreviousOrientationWasLandscape = true
            } else {
                devicePreviousOrientationWasLandscape = false
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
    @Published public var deviceRotationAngle : Angle = Angle(degrees: 0)
    @Published public var deviceLandscapeRotationAngle : Angle = Angle(degrees: 90)
    @Published public var devicePreviousOrientationWasLandscape : Bool = false

    
    static var shared = ACScene()
}
