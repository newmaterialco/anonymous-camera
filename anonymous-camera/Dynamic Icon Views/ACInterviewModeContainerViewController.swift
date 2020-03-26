//
//  ACInterviewModeContainerViewController.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit
import SwiftUI
import SnapKit

class ACInterviewModeContainerViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let track = UIView()
    let thumb = UIView()
    let interviewControlHostingVC = UIHostingController(rootView: ACInterviewControl())

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .blue
                
        self.view.addSubview(track)
        track.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
        
        track.addSubview(thumb)
        thumb.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        let dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.interviewControlWasPanned(gestureRecognizer:)))
        dragGestureRecognizer.delegate = self
        
        interviewControlHostingVC.view.addGestureRecognizer(dragGestureRecognizer)
        interviewControlHostingVC.view.backgroundColor = .yellow
        thumb.addSubview(interviewControlHostingVC.view)
        interviewControlHostingVC.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func interviewControlWasPanned (gestureRecognizer : UIPanGestureRecognizer) {
        
        let positionInView = gestureRecognizer.location(in: track)
        
        if gestureRecognizer.state == .began {
            
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))
            
            self.thumb.snp.remakeConstraints { make in
                make.centerX.equalTo(track.snp.leading).offset(positionInView.x).priority(.medium)
                make.leading.greaterThanOrEqualTo(self.track.snp.leading).priority(.high)
                make.trailing.lessThanOrEqualTo(self.track.snp.trailing).priority(.high)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }

            animator.addAnimations {
                self.view.layoutIfNeeded()
            }

            animator.startAnimation()

        } else if gestureRecognizer.state == .changed {
            
            self.thumb.snp.remakeConstraints { make in
                make.centerX.equalTo(track.snp.leading).offset(positionInView.x).priority(.medium)
                make.leading.greaterThanOrEqualTo(self.track.snp.leading).priority(.high)
                make.trailing.lessThanOrEqualTo(self.track.snp.trailing).priority(.high)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            
        } else {
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))
            
            self.thumb.snp.remakeConstraints { make in
                make.centerX.equalTo(track.snp.leading).offset(positionInView.x).priority(.medium)
                make.leading.greaterThanOrEqualTo(self.track.snp.leading).priority(.high)
                make.trailing.lessThanOrEqualTo(self.track.snp.trailing).priority(.high)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }

            animator.addAnimations {
                self.view.layoutIfNeeded()
            }

            animator.startAnimation()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ACInterviewModeContainerView : UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> ACInterviewModeContainerViewController {
        let vc = ACInterviewModeContainerViewController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACInterviewModeContainerViewController, context: Context) {
    }
}

struct ACInterviewModeContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ACInterviewModeContainerView()
    }
}
