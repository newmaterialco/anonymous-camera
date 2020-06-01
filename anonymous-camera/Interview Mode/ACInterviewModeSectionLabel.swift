//
//  ACInterviewModeSectionView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 29/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit

class ACInterviewModeSectionLabel: UIView {
    
    let labelContainer = AAView()
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    var labels : [UILabel] = []

    init() {
        super.init(frame : CGRect.zero)
        
        self.addSubview(labelContainer)
        labelContainer.configureShadow(withColor: .black, radius: 24, opacity: 0.24, andOffset: CGSize.zero)
        labelContainer.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        labelContainer.contentView.addSubview(scrollView)
        scrollView.clipsToBounds = false
        scrollView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        stackView.axis = .vertical
        stackView.alignment = .center
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
            make.leading.equalTo(labelContainer)
            make.trailing.equalTo(labelContainer)
        }
        
        self.configureForFilters(filters: ACAnonymisation.shared.filters)
    }
    
    var hide = false
    
    func setHidden (shouldBeHidden : Bool) {
                
        if shouldBeHidden != self.hide {
            self.hide = shouldBeHidden
                        
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.72, frequencyResponse: 0.32))
            
            animator.addAnimations {
                if shouldBeHidden {
                    self.alpha = 0
                    self.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                } else {
                    self.alpha = 1
                    self.transform = CGAffineTransform(scaleX: 1, y: 1)
                }
            }
            
            animator.startAnimation()

        }
    }
    
    func scrollToFilter (filter : ACFilter) {
                
        self.layoutIfNeeded()
        scrollView.contentSize = stackView.bounds.size
                
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: UISpringTimingParameters(dampingRatio: 0.68, frequencyResponse: 0.5))
        
        animator.addAnimations {
            for (index, f) in ACAnonymisation.shared.filters.enumerated() {
                
                if f.filterIdentifier == filter.filterIdentifier {
                    
                    var frame: CGRect = self.scrollView.frame
                    frame.origin.y = frame.size.height * CGFloat(index)
                    self.scrollView.scrollRectToVisible(frame, animated: false)
                    self.labels[index].alpha = 1

                } else {
                    self.labels[index].alpha = 0
                }
            }
        }
        
        animator.startAnimation()
    }
    
    func configureForFilters (filters : [ACFilter]) {
        
        labels = []
        
        for filter in filters {
            let label = UILabel()
            label.textAlignment = .center
            label.alpha = 0
            label.textColor = .white
            label.font = UIFont.roundedSystemFont(ofSize: 28, andWeight: .thin)
            label.text = filter.name
            stackView.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
            }
            
            labels.append(label)
        }
        
        labelContainer.snp.remakeConstraints { make in
            make.pinAllEdgesToSuperView()
            make.height.equalTo(stackView.arrangedSubviews[0].snp.height)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
