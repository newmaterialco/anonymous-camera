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
    var interviewControl = ACInterviewControl()
    let closeInterviewModeControlHostingVC = UIHostingController(rootView: ACCloseInterviewModeControl())
    var interviewModeIsOn : Bool = false {
        didSet {
            if interviewModeIsOn {
                self.dividerLine.alpha = 1
                ACAnonymisation.shared.interviewModeDividerXOffset = thumb.frame.midX
            } else {
                self.dividerLine.alpha = 0
                self.configureForInterviewModeDeactivated()
            }

        }
    }
    var dividerLine = UIView()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                        
        self.view.addSubview(track)
        track.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
        
        closeInterviewModeControlHostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        closeInterviewModeControlHostingVC.view.backgroundColor = .clear

        
        track.addSubview(closeInterviewModeControlHostingVC.view)
        closeInterviewModeControlHostingVC.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(track.snp.height)
        }
        
        track.addSubview(thumb)
        thumb.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        dividerLine.backgroundColor = .white
        dividerLine.alpha = 0
        self.view.insertSubview(dividerLine, belowSubview: track)
        dividerLine.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.centerX.equalTo(thumb)
        }
        
        let dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.interviewControlWasPanned(gestureRecognizer:)))
        dragGestureRecognizer.delegate = self
        
        let interviewControlHostingVC = UIHostingController(rootView: interviewControl)
        interviewControlHostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        interviewControlHostingVC.view.addGestureRecognizer(dragGestureRecognizer)
        interviewControlHostingVC.view.backgroundColor = .clear
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
    
    private func overlappingCloseElement () -> Bool {
        if thumb.frame.intersects(closeInterviewModeControlHostingVC.view.frame) {
            ACScene.shared.interviewModeControlIsHoveringOverClose = true
            //print("OVERLAPPING")
            
            return true
            
        } else {
            ACScene.shared.interviewModeControlIsHoveringOverClose = false
            //print("NOT OVERLAPPING")

            return false
        }
    }
    
    private var storedXPositionInView : CGFloat = 0
    
    @objc func interviewControlWasPanned (gestureRecognizer : UIPanGestureRecognizer) {
        
        if ACAnonymisation.shared.interviewModeIsOn {
            let xTranslationInView = gestureRecognizer.translation(in: track).x
            storedXPositionInView = storedXPositionInView + xTranslationInView
            gestureRecognizer.setTranslation(CGPoint.zero, in: track)
            
            if gestureRecognizer.state == .began {
                
                storedXPositionInView = thumb.frame.midX
                
                let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))
                
                self.thumb.snp.remakeConstraints { make in
                    
                    if storedXPositionInView == 0 {
                        make.centerX.equalToSuperview().priority(.medium)
                    } else {
                        make.centerX.equalTo(track.snp.leading).offset(storedXPositionInView).priority(.medium)
                    }
                    make.top.equalToSuperview()
                    make.bottom.equalToSuperview()
                }

                animator.addAnimations {
                    self.view.layoutIfNeeded()
                }

                animator.startAnimation()

            } else if gestureRecognizer.state == .changed {
                
                overlappingCloseElement()
                self.thumb.snp.remakeConstraints { make in
                    make.centerX.equalTo(track.snp.leading).offset(storedXPositionInView).priority(.medium)
                    make.leading.greaterThanOrEqualTo(self.track.snp.leading).priority(.high)
                    make.trailing.lessThanOrEqualTo(self.track.snp.trailing).priority(.high)
                    make.top.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
                ACAnonymisation.shared.interviewModeDividerXOffset = thumb.frame.midX
            } else {
                let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))
                                
                if !overlappingCloseElement() {
                                        
                    self.thumb.snp.remakeConstraints { make in
                        make.centerX.equalTo(track.snp.leading).offset(storedXPositionInView).priority(.medium)
                        make.leading.greaterThanOrEqualTo(self.track.snp.leading).priority(.high)
                        make.trailing.lessThanOrEqualTo(self.track.snp.trailing).priority(.high)
                        make.top.equalToSuperview()
                        make.bottom.equalToSuperview()
                    }
                    
                } else {
                    
                    self.configureForInterviewModeDeactivated()
                }
                
                ACScene.shared.interviewModeControlIsHoveringOverClose = false

                animator.addAnimations {
                    self.view.layoutIfNeeded()
                }

                animator.startAnimation()
            }

        }
    }
    
    private func configureForInterviewModeDeactivated () {
        
        print("CONFIGURE")
        
        self.storedXPositionInView = 0
        
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))
                
        self.thumb.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(self.track.snp.leading).priority(.high)
            make.trailing.lessThanOrEqualTo(self.track.snp.trailing).priority(.high)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        animator.addAnimations {
            ACAnonymisation.shared.interviewModeConfiguration = .off
            self.view.layoutIfNeeded()
        }

        animator.startAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ACInterviewModeContainerView : UIViewControllerRepresentable {
    
    var interviewModeIsOn : Bool
    
    func makeUIViewController(context: Context) -> ACInterviewModeContainerViewController {
        let vc = ACInterviewModeContainerViewController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACInterviewModeContainerViewController, context: Context) {
        
        viewController.interviewModeIsOn = interviewModeIsOn
        
    }
}

struct ACInterviewModeContainerView_Previews: PreviewProvider {
    
    static var interviewModeIsOn = false
    
    static var previews: some View {
        ACInterviewModeContainerView(interviewModeIsOn: interviewModeIsOn)
    }
}
