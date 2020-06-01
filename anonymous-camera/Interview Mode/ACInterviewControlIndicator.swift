//
//  ACInterviewControlIndicator.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 29/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit

class ACInterviewControlIndicator: UIView {
    
    let iconContainer = AAView()
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    var icons : [UIImageView] = []

    init() {
        super.init(frame: CGRect.zero)
        
        self.addSubview(iconContainer)
        iconContainer.configureShadow(withColor: .black, radius: 24, opacity: 0.24, andOffset: CGSize.zero)
        iconContainer.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        iconContainer.contentView.addSubview(scrollView)
        scrollView.clipsToBounds = false
        scrollView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        stackView.axis = .vertical
        stackView.alignment = .center
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
            make.leading.equalTo(iconContainer)
            make.trailing.equalTo(iconContainer)
        }
        
        self.configureForFilters(filters: ACAnonymisation.shared.filters)

    }
    
    func configureForFilters (filters : [ACFilter]) {
        
        icons = []
        
        for filter in filters {
            let icon = UIImageView()
            icon.image = filter.icon
            stackView.addArrangedSubview(icon)
            icon.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
            }
            
            icons.append(icon)
        }
        
        iconContainer.snp.remakeConstraints { make in
            make.pinAllEdgesToSuperView()
            make.height.equalTo(stackView.arrangedSubviews[0].snp.height)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
