//
//  AppDelegate.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit

#if !targetEnvironment(simulator)
let anonymous = Anon()
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Anon.requestPhotosAccess { _ in
            Anon.requestMicrophoneAccess { _ in
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }


    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        InAppManager.shared.deactivate()
    }
    
}

