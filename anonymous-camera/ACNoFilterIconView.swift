//
//  ACNoFilterIconView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI
import SnapKit
import SceneKit
import SwifterSwift

class ACNoFilterIconHostingController: UIViewController {
    
    let sceneView = SCNView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(sceneView)
        sceneView.autoenablesDefaultLighting = true
        sceneView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        sceneView.backgroundColor = .clear
        if let facePath = Bundle.main.path(forResource: "face", ofType: "dae"), let scene = try? SCNScene(url: URL(fileURLWithPath: facePath), options: nil), let node = scene.rootNode.childNode(withName: "root", recursively: true) {
            let mainScene = SCNScene()
            mainScene.rootNode.addChildNode(node)
            sceneView.scene = mainScene
            
            MotionManager.shared.start { pitch, roll, yaw in
                let matrix = SCNMatrix4Identity
                let pitchRot = SCNMatrix4Rotate(matrix, pitch.degreesToRadians.float, 1, 0, 0)
                let rollRot = SCNMatrix4Rotate(pitchRot, roll.degreesToRadians.float, 0, 0, 1)
                let yawRot = SCNMatrix4Rotate(rollRot, yaw.degreesToRadians.float, 0, 1, 0)
                mainScene.rootNode.transform = yawRot
            }
        }
    }
}

struct ACNoFilterIconView : UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ACNoFilterIconHostingController {
        let vc = ACNoFilterIconHostingController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACNoFilterIconHostingController, context: Context) {
    }
}

struct ACNoFilterIconView_Previews: PreviewProvider {
    static var previews: some View {
        ACNoFilterIconView()
    }
}
