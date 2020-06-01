//
//  MainHostingViewController.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit
import SwiftUI
import SnapKit

class MainHostingViewController: UIViewController {
    
    let containerViewController = UIHostingController(rootView: ContainerView())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(containerViewController.view)
        containerViewController.view.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        ACAnonymisation.shared.select(filter: ACAnonymisation.shared.filters[1])
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        if ACScene.shared.deviceOrientation.isLandscape {
            return false
        } else {
            return true
        }
    }
}

struct ACMainView : UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> MainHostingViewController {
        let vc = MainHostingViewController()
        return vc
    }
    
    func updateUIViewController(_ viewController: MainHostingViewController, context: Context) {
    }
}

struct ACMainView_Previews: PreviewProvider {
    static var previews: some View {
        ACMainView()
    }
}
