//
//  ACNoFilterIconView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

class ACNoFilterIconHostingController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .blue
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
