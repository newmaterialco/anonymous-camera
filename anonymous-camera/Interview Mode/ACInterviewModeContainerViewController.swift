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
    let closeInterviewModeLeadingHitArea = UIView()
    let closeInterviewModeTrailingHitArea = UIView()
    let closeInterviewModeControlHostingVC = UIHostingController(rootView: ACCloseInterviewModeControl())
    
    let leadingSection = ACInterviewModeSectionView()
    let trailingSection = ACInterviewModeSectionView()
    
    var interviewModeControlIsBeingPanned : Bool = false {
        didSet {
            if interviewModeIsOn {
                if interviewModeControlIsBeingPanned {
                    self.leadingSection.label.setHidden(shouldBeHidden: false)
                    self.trailingSection.label.setHidden(shouldBeHidden: false)
                } else {
                    self.leadingSection.label.setHidden(shouldBeHidden: true)
                    self.trailingSection.label.setHidden(shouldBeHidden: true)
                }
                
            } else {
                self.leadingSection.label.setHidden(shouldBeHidden: true)
                self.trailingSection.label.setHidden(shouldBeHidden: true)
            }
        }
    }
    

    
    var interviewModeIsOn : Bool = false {
        didSet {
            if interviewModeIsOn {
                self.leadingSection.label.setHidden(shouldBeHidden: false)
                self.trailingSection.label.setHidden(shouldBeHidden: false)
                ACAnonymisation.shared.interviewModeDividerXOffset = thumb.frame.midX
            } else {
                self.leadingSection.label.setHidden(shouldBeHidden: true)
                self.trailingSection.label.setHidden(shouldBeHidden: true)
                self.configureForInterviewModeDeactivated(edges: nil)
                self.leadingSection.label.setHidden(shouldBeHidden: true)
                self.trailingSection.label.setHidden(shouldBeHidden: true)
            }
            
            self.interviewModeIsTurnedOn(on: interviewModeIsOn)
        }
    }
    
    var orientation : UIDeviceOrientation = UIDevice.current.orientation {
        didSet {
            if oldValue != orientation {
                self.updateOrientation()
            }
        }
    }
    
    var interviewModeConfiguration : ACAnonymisation.ACInterviewModeConfiguration = .off {
        didSet {
            updateEffect()
        }
    }
    
    var selectedFilter : ACFilter = ACAnonymisation.shared.selectedFilterGroup.filters[0] {
        didSet {
            updateEffect()
        }
    }
        
    var dividerLine = UIView()

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    func interviewModeIsTurnedOn (on : Bool) {
        
        UIView.animate(withDuration: 0.3) {
            if on {
                self.dividerLine.alpha = 1
                self.leadingSection.alpha = 1
                self.trailingSection.alpha = 1
                
            } else {
                self.dividerLine.alpha = 0
                self.leadingSection.alpha = 0
                self.trailingSection.alpha = 0

            }
        }
    }
    
    func updateEffect () {
        
        if interviewModeConfiguration == .off {
            
        } else {
            
            if interviewModeConfiguration == .effectTrailing {
                
                leadingSection.label.scrollToFilter(filter: ACAnonymisation.shared.allAvailableFilters[0])
                trailingSection.label.scrollToFilter(filter: selectedFilter)

            } else if interviewModeConfiguration == .effectLeading {
                
                leadingSection.label.scrollToFilter(filter: selectedFilter)
                trailingSection.label.scrollToFilter(filter: ACAnonymisation.shared.allAvailableFilters[0])
            }
            
        }
        
    }
    
    func updateOrientation () {
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))

        if orientation == .landscapeLeft {
            
            closeInterviewModeControlHostingVC.view.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.leading.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(track.snp.height)
            }
            
            animator.addAnimations {
                self.view.layoutIfNeeded()
            }

            animator.startAnimation()

            
        } else if orientation == .landscapeRight {
            
            closeInterviewModeControlHostingVC.view.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(track.snp.height)
            }
            
            animator.addAnimations {
                self.view.layoutIfNeeded()
            }

            animator.startAnimation()

        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
                                        
        self.view.addSubview(track)
        track.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
        
        track.addSubview(closeInterviewModeLeadingHitArea)
        closeInterviewModeLeadingHitArea.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(24)
        }
        
        track.addSubview(closeInterviewModeTrailingHitArea)
        closeInterviewModeTrailingHitArea.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(24)
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
            make.height.equalToSuperview().multipliedBy(3)
            make.centerY.equalToSuperview()
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
        
        leadingSection.alpha = 0
        leadingSection.label.setHidden(shouldBeHidden: true)
        self.view.addSubview(leadingSection)
        leadingSection.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalTo(dividerLine.snp.leading)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        trailingSection.alpha = 0
        trailingSection.label.setHidden(shouldBeHidden: true)
        self.view.addSubview(trailingSection)
        trailingSection.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.leading.equalTo(dividerLine.snp.trailing)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    private func overlappingLeadingCloseElement () -> Bool {
        if (thumb.frame.intersects(closeInterviewModeLeadingHitArea.frame))  {
            return true
            
        } else {
            return false
        }
    }
    
    private func overlappingTrailingCloseElement () -> Bool {
        if (thumb.frame.intersects(closeInterviewModeTrailingHitArea.frame))  {
            return true
            
        } else {
            return false
        }
    }
    
    private func hoveringOverClose () -> Bool {
        if (overlappingTrailingCloseElement () || overlappingLeadingCloseElement ()) {
            ACScene.shared.interviewModeControlIsHoveringOverClose = true
            return true
        } else {
            ACScene.shared.interviewModeControlIsHoveringOverClose = false
            return false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private var storedXPositionInView : CGFloat = 0
    private var lastTranslate : CGPoint = CGPoint.zero
    private var previousTranslate : CGPoint = CGPoint.zero
    private var lastTime : TimeInterval = 0
    private var previousTime : TimeInterval = 0
    
    @objc func interviewControlWasPanned (gestureRecognizer : UIPanGestureRecognizer) {
                
        if ACAnonymisation.shared.interviewModeIsOn {
            
            let translate = gestureRecognizer.translation(in: track)

            let xTranslationInView = gestureRecognizer.translation(in: track).x
            storedXPositionInView = storedXPositionInView + (xTranslationInView - lastTranslate.x)
            
            if gestureRecognizer.state == .began {
                
                ACScene.shared.interviewModeControlIsBeingTouched = true
                
                lastTime = Date.timeIntervalSinceReferenceDate
                lastTranslate = translate
                previousTime = lastTime
                previousTranslate = lastTranslate
                
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
                
                previousTime = lastTime
                previousTranslate = lastTranslate
                lastTime = Date.timeIntervalSinceReferenceDate
                lastTranslate = translate
                
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
                
                ACScene.shared.interviewModeControlIsBeingTouched = false
                                
                var animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))
                                
                if !(overlappingLeadingCloseElement() && overlappingTrailingCloseElement()) {
                    
                    animator = UIViewPropertyAnimator(duration: 0.2, timingParameters: UISpringTimingParameters(dampingRatio: 0.8, frequencyResponse: 0.5))
                    
                    var swipeVelocity = CGPoint.zero
                    let seconds = Date.timeIntervalSinceReferenceDate - previousTime
                    swipeVelocity = CGPoint(x: (lastTranslate.x - previousTranslate.x)/CGFloat(seconds), y: 0)
                    
                    let intertiaSeconds = 0.2
                    storedXPositionInView = storedXPositionInView + swipeVelocity.x * CGFloat(intertiaSeconds)
                                                            
                    self.thumb.snp.remakeConstraints { make in
                        make.centerX.equalTo(track.snp.leading).offset(storedXPositionInView).priority(.medium)
                        make.leading.greaterThanOrEqualTo(self.track.snp.leading).priority(.high)
                        make.trailing.lessThanOrEqualTo(self.track.snp.trailing).priority(.high)
                        make.top.equalToSuperview()
                        make.bottom.equalToSuperview()
                    }
                    
                    animator.addAnimations {
                        self.view.layoutIfNeeded()
                    }
                    
                    animator.addCompletion { _ in
                                                
                        if self.overlappingLeadingCloseElement() {
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 1000)) {
                                self.configureForInterviewModeDeactivated(edges: .leading)
                            }
                        } else if self.overlappingTrailingCloseElement() {
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 1000)) {
                                self.configureForInterviewModeDeactivated(edges: .trailing)
                            }
                        }
                    }

                    animator.startAnimation()

                    
                } else {
                                        
                    if overlappingLeadingCloseElement() {
                        self.configureForInterviewModeDeactivated(edges: .leading)
                    } else if overlappingTrailingCloseElement() {
                        self.configureForInterviewModeDeactivated(edges: .trailing)
                    }
                    
                }
            }
        }
        
        let _ = self.hoveringOverClose()
    }
    
    private func configureForInterviewModeDeactivated (edges : Edge?) {
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
        
        animator.addCompletion { _ in
            let _ = self.hoveringOverClose()
        }

        animator.startAnimation()
        
        let generator = UISelectionFeedbackGenerator()

        if let e = edges {
            if e == .leading {
                if interviewModeConfiguration == .effectLeading {
                    generator.selectionChanged()
                    ACAnonymisation.shared.select(filterGroup: ACAnonymisation.shared.filterGroups[0])
                }
            } else if e == .trailing {
                if interviewModeConfiguration == .effectTrailing {
                    generator.selectionChanged()
                    ACAnonymisation.shared.select(filterGroup: ACAnonymisation.shared.filterGroups[0])
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ACInterviewModeContainerView : UIViewControllerRepresentable {
    
    var interviewModeIsOn : Bool
    var orientation : UIDeviceOrientation
    var interviewModeConfiguration : ACAnonymisation.ACInterviewModeConfiguration
    var selectedFilter : ACFilter
    var interviewModeControlIsBeingPanned : Bool
    
    func makeUIViewController(context: Context) -> ACInterviewModeContainerViewController {
        let vc = ACInterviewModeContainerViewController()
        return vc
    }
    
    func updateUIViewController(_ viewController: ACInterviewModeContainerViewController, context: Context) {
        viewController.interviewModeIsOn = interviewModeIsOn
        viewController.orientation = orientation
        viewController.interviewModeConfiguration = interviewModeConfiguration
        viewController.selectedFilter = selectedFilter
        viewController.interviewModeControlIsBeingPanned = interviewModeControlIsBeingPanned
    }
}

struct ACInterviewModeContainerView_Previews: PreviewProvider {
    
    static var interviewModeIsOn = false
    static var orientation = UIDeviceOrientation.portrait
    
    static var previews: some View {
        ACInterviewModeContainerView(interviewModeIsOn: interviewModeIsOn, orientation: orientation, interviewModeConfiguration: .off, selectedFilter: ACAnonymisation.shared.allAvailableFilters[0], interviewModeControlIsBeingPanned: false)
    }
}

class TranslucentTouchView : UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !(subview.isHidden) && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
