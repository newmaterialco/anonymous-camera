//
//  ACInterviewModeSectionView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 29/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit

class ACInterviewModeSectionView: UIView {
    
    let label = ACInterviewModeSectionLabel()

    init() {
        super.init(frame: CGRect.zero)
        
        self.isUserInteractionEnabled = false
        
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if ACAnonymisation.shared.interviewModeIsOn {
            if ACScene.shared.interviewModeControlIsBeingTouched {
                if (self.frame.width - 42) < label.frame.width {
                    label.setHidden(shouldBeHidden: true)
                } else {
                    label.setHidden(shouldBeHidden: false)
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
