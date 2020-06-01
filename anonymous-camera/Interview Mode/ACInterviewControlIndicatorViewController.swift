//
//  ACInterviewControlIndicatorViewController.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 29/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI
import UIKit

class ACInterviewControlIndicatorViewController: UIViewController {

}

struct ACInterviewControlIndicatorView : UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> ACInterviewControlIndicatorViewController {
        let vc = ACInterviewControlIndicatorViewController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACInterviewControlIndicatorViewController, context: Context) {
    }
}

struct ACInterviewControlIndicatorView_Previews: PreviewProvider {
    
    
    static var previews: some View {
        ACInterviewControlIndicatorView()
    }
}
