//
//  ACCameraFeedViewController.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit
import SwiftUI
import SnapKit

class ACCameraFeedViewController: UIViewController {
        
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
        //anonymous.showMask(type: .none, detection: .face)
        #endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ACViewfinderView : UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> ACCameraFeedViewController {
        let vc = ACCameraFeedViewController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACCameraFeedViewController, context: Context) {
    }
}

struct ACViewfinderView_Previews: PreviewProvider {
    static var previews: some View {
        ACViewfinderView()
    }
}

extension ACCameraFeedViewController: AnonDelegate {
    func didSwitch(from: Anon.AnonState, to: Anon.AnonState) {
    }
    
    func updated(faces: [Anon.AnonFace]) {
        ACAnonymisation.shared.faces = faces
    }
    func rotationChange(orientation: UIDeviceOrientation) {
        
        if !orientation.isFlat && !(orientation == .portraitUpsideDown) {
            ACScene.shared.deviceOrientation = orientation
        }
    }
}
