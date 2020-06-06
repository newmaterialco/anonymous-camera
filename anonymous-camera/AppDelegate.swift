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

let reachability = try! Reachability()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Anon.requestPhotosAccess { _ in
            Anon.requestMicrophoneAccess { _ in
            }
        }
        
        checkForProducts()
        checkIfPro()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
          try reachability.startNotifier()
        }catch{
          print("could not start reachability notifier")
        }
        return true
    }
    
    func checkIfPro () {
        ACScene.shared.proPurchased = InAppManager.shared.isPro
    }
    
    func checkForProducts () {
        InAppManager.shared.pro { product in
            
            print("products available")
            
            ACScene.shared.product = product
            ACScene.shared.productsAvailable = true
        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
      let reachability = note.object as! Reachability

      switch reachability.connection {
      case .wifi:
        ACScene.shared.internetConnection = true
        checkForProducts()
        checkIfPro()

      case .cellular:
          ACScene.shared.internetConnection = true
        checkForProducts()
        checkIfPro()

      case .unavailable:
        ACScene.shared.internetConnection = false
      case .none:
        ACScene.shared.internetConnection = false
        }
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

