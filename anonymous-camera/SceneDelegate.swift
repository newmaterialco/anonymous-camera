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
        let contentView = ACMainView()
            .edgesIgnoringSafeArea(.all)
            .environmentObject(sceneInformation)
            .environmentObject(anonymisation)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = true
        self.anonymisation.interviewModeConfiguration = .off
    }

    func sceneWillResignActive(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = false
        self.sceneInformation.isDraggingBottomSheet = false
        self.anonymisation.interviewModeConfiguration = .off
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = false
        self.sceneInformation.isDraggingBottomSheet = false
        self.anonymisation.interviewModeConfiguration = .off
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        Anon.updatePermissions()
        self.sceneInformation.sceneIsActive = true
        self.anonymisation.interviewModeConfiguration = .off
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        self.sceneInformation.sceneIsActive = false
        self.sceneInformation.isDraggingBottomSheet = false
        self.anonymisation.interviewModeConfiguration = .off
    }
}
