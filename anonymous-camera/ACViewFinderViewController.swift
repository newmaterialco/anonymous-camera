//
//  ACViewFinderViewController.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit
import SwiftUI
import SnapKit

class ACViewfinderViewController: UIViewController {
        
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if !targetEnvironment(simulator)
        anonymous.delegate = self
        #endif
        
        #if !targetEnvironment(simulator)
        self.view.addSubview(anonymous.shaderView)
         anonymous.shaderView.snp.remakeConstraints { make in
            make.edges.equalTo(self.view.snp.edges)
         }
         #endif
        
        self.view.backgroundColor = .black
        
        #if !targetEnvironment(simulator)
        anonymous.showCamera(facing: .front)
        anonymous.watermark = UIImage(named: "AC_WATERMARK")
        anonymous.showMask(type: .none, detection: .face)
        #endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ACViewfinderView : UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> ACViewfinderViewController {
        let vc = ACViewfinderViewController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACViewfinderViewController, context: Context) {
    }
}

extension ACViewfinderViewController: AnonDelegate {
    func didSwitch(from: Anon.AnonState, to: Anon.AnonState) {
        print("did switch from \(from.camera), \(from.detection), \(from.mask) to \(to.camera), \(to.detection), \(to.mask)")
    }
    func updatedFaceRects(rects: [CGRect]) {
//        viewfinder.interface.updateFaceRectangles(withRectangles: rects)
    }
    func rotationChange(orientation: UIDeviceOrientation) {
        
        if !orientation.isFlat && !(orientation == .portraitUpsideDown) {
            ACScene.shared.deviceOrientation = orientation
        }
                
//        if !orientation.isFlat {
//                if orientation != currentOrientation {
//
//                    if orientation.isPortrait {
//                        self.statusBarAnimationStyle = .slide
//                        self.shouldHideStatusBar = false
//                    } else {
//                        self.statusBarAnimationStyle = .slide
//                        self.shouldHideStatusBar = true
//                    }
//
//                    UIView.animate(withDuration: 0.26) {
//                        self.setNeedsStatusBarAppearanceUpdate()
//                    }
//
//                    var shouldAnimate : Bool = true
//
//                    if currentOrientation == .unknown && orientation != .unknown {
//                        shouldAnimate = false
//                    }
//
//                    self.currentOrientation = orientation
//                    let userInfo : [String : Any] = ["deviceOrientation" : orientation, "shouldAnimate" : shouldAnimate]
//                    NotificationCenter.default.post(name: .rotationChanged, object: nil, userInfo: userInfo)
//
//            }
//        }
    }
}
