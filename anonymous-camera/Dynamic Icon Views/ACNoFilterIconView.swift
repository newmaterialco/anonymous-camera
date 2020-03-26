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
    var diffuseColors: [String: UIColor] = [:]
    var counter = 0.0
    var resettingFace = false
    var resetPitch = 0.0
    var resetRoll = 0.0
    var resetYaw = 0.0
    var resetDamping = 0.9
    
    func resetFace() {
        resettingFace = true
    }
    
    func animateFaceColor(faceColor: UIColor, featureColor: UIColor, duration: Double) {
        if let faceNode = faceNode {
            for childNode in faceNode.childNodes {
                childNode.removeAllActions()
                if let name = childNode.name, let diffuse = childNode.geometry?.materials.first?.diffuse {
                    let fromColor = diffuseColors[name]
                    var toColor: UIColor?
                    if faceNodes.contains(name) { toColor = faceColor }
                    else if featureNodes.contains(name) { toColor = featureColor }
                    if let fromColor = fromColor, let toColor = toColor {
                        if duration > 0 {
                            let action = SCNAction.customAction(duration: duration, action: { (node, elapsedTime) in
                                let percentage = elapsedTime / duration.cgFloat
                                if let color = fromColor.interpolateRGBColorTo(toColor, fraction: percentage) {
                                    diffuse.contents = color
                                }
                            })
                            childNode.runAction(action)
                        }
                        else { diffuse.contents = toColor }
                    }
                    diffuseColors[name] = toColor
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
            
            for childNode in node.childNodes {
                if let name = childNode.name, let contents = childNode.geometry?.materials.first?.diffuse.contents, let col = contents as? UIColor {
                    diffuseColors[name] = col
                }
            }
            
            animateFaceColor(faceColor: UIColor(red: 1, green: 1, blue: 1, alpha: 1), featureColor: UIColor(red: 0, green: 0, blue: 0, alpha: 1), duration: 0.0)
            
            if MotionManager.shared.isAvailable {
                MotionManager.shared.onData { (pitch, roll, yaw) in
                    if self.initialPitch == 0 && self.initialRoll == 0 && self.initialYaw == 0 {
                        self.initialPitch = pitch
                        self.initialRoll = roll
                        self.initialYaw = yaw
                    }
                    if self.resettingFace {
                        self.resetPitch *= self.resetDamping
                        self.resetRoll *= self.resetDamping
                        self.resetYaw *= self.resetDamping
                        let matrix = SCNMatrix4Identity
                        let pitchRot = SCNMatrix4Rotate(matrix, self.resetPitch.degreesToRadians.float, 1, 0, 0)
                        let rollRot = SCNMatrix4Rotate(pitchRot, self.resetRoll.degreesToRadians.float, 0, 0, 1)
                        let yawRot = SCNMatrix4Rotate(rollRot, self.resetYaw.degreesToRadians.float, 0, 1, 0)
                        mainScene.rootNode.transform = yawRot
                        
                        if fabs(self.resetPitch) < 1.0 && fabs(self.resetRoll) < 1.0 && fabs(self.resetYaw) < 1.0 {
                            self.resettingFace = false
                            self.initialPitch = 0
                            self.initialRoll = 0
                            self.initialYaw = 0
                        }
                    }
                    else {
                        
                        var diffPitch = pitch - self.initialPitch
                        var diffRoll = roll - self.initialRoll
                        var diffYaw = yaw - self.initialYaw
                        
                        diffPitch *= (self.constraint / 720)
                        diffRoll *= (self.constraint / 360)
                        diffYaw *= (self.constraint / 360)
                        
                        // pitchRot - up down
                        // yawRot - left right
                        // rollRot - around
                        let matrix = SCNMatrix4Identity
                        let pitchRot = SCNMatrix4Rotate(matrix, diffPitch.degreesToRadians.float, 1, 0, 0)
                        let rollRot = SCNMatrix4Rotate(pitchRot, diffRoll.degreesToRadians.float, 0, 0, 1)
                        let yawRot = SCNMatrix4Rotate(rollRot, diffYaw.degreesToRadians.float, 0, 1, 0)
                        mainScene.rootNode.transform = yawRot
                        
                        self.resetPitch = diffPitch
                        self.resetRoll = diffRoll
                        self.resetYaw = diffYaw
                    }
                }
            }
        }
    }
}

struct ACNoFilterIconView : UIViewControllerRepresentable {
    
    var isSelected : Bool
    
    func makeUIViewController(context: Context) -> ACNoFilterIconHostingController {
        let vc = ACNoFilterIconHostingController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACNoFilterIconHostingController, context: Context) {
        
        if isSelected {
            viewController.animateFaceColor(faceColor: UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 1), featureColor: UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1), duration: 0.2)
        } else {
            viewController.animateFaceColor(faceColor: UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1), featureColor: UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 1), duration: 0.2)
        }
        
        viewController.resetFace()
    }
}

struct ACNoFilterIconView_Previews: PreviewProvider {
    
    static var isSelected = false
    
    static var previews: some View {
        ACNoFilterIconView(isSelected: isSelected)
    }
}
