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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView().environmentObject(sceneInformation)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = true
    }

    func sceneWillResignActive(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = false
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
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
