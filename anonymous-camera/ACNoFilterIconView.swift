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

extension UIColor {
    func interpolateRGBColorTo(_ end: UIColor, fraction: CGFloat) -> UIColor? {
        let f = min(max(0, fraction), 1)
        guard let c1 = self.cgColor.components, let c2 = end.cgColor.components else { return nil }
        let r: CGFloat = CGFloat(c1[0] + (c2[0] - c1[0]) * f)
        let g: CGFloat = CGFloat(c1[1] + (c2[1] - c1[1]) * f)
        let b: CGFloat = CGFloat(c1[2] + (c2[2] - c1[2]) * f)
        let a: CGFloat = CGFloat(c1[3] + (c2[3] - c1[3]) * f)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

class ACNoFilterIconHostingController: UIViewController {
    
    var faceNode: SCNNode?
    let sceneView = SCNView()
    var initialPitch = 0.0
    var initialRoll = 0.0
    var initialYaw = 0.0
    let constraint = 180.0
    let faceNodes = ["node_a"]
    let featureNodes = ["node_b", "node_c", "node_d"]
    
    func animateFaceColor(faceColor: UIColor, featureColor: UIColor, duration: Double) {
        if let faceNode = faceNode {
            for childNode in faceNode.childNodes {
                if let name = childNode.name, let geometry = childNode.geometry {
                    if faceNodes.contains(name) {
                        geometry.firstMaterial?.diffuse.contents = faceColor
                    }
                    else if featureNodes.contains(name) {
                        geometry.firstMaterial?.diffuse.contents = featureColor
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(sceneView)
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = false
        sceneView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        sceneView.backgroundColor = .clear
        if let facePath = Bundle.main.path(forResource: "face", ofType: "dae"), let scene = try? SCNScene(url: URL(fileURLWithPath: facePath), options: nil), let node = scene.rootNode.childNode(withName: "root", recursively: true) {
            let mainScene = SCNScene()
            mainScene.rootNode.addChildNode(node)
            sceneView.scene = mainScene
            faceNode = node
            animateFaceColor(faceColor: .white, featureColor: .black, duration: 1.0)
            
            MotionManager.shared.start { pitch, roll, yaw in
                if self.initialPitch == 0 && self.initialRoll == 0 && self.initialYaw == 0 {
                    self.initialPitch = pitch
                    self.initialRoll = roll
                    self.initialYaw = yaw
                }
                var diffPitch = pitch - self.initialPitch
                var diffRoll = roll - self.initialRoll
                var diffYaw = yaw - self.initialYaw
                
                diffPitch *= (self.constraint / 360)
                diffRoll *= (self.constraint / 360)
                diffYaw *= (self.constraint / 360)

                let matrix = SCNMatrix4Identity
                let pitchRot = SCNMatrix4Rotate(matrix, diffPitch.degreesToRadians.float, 1, 0, 0)
                let rollRot = SCNMatrix4Rotate(pitchRot, diffRoll.degreesToRadians.float, 0, 0, 1)
                let yawRot = SCNMatrix4Rotate(rollRot, diffYaw.degreesToRadians.float, 0, 1, 0)
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
