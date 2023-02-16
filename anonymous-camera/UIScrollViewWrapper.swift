//
//  UIScrollViewWrapper.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 30/05/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI
import UIKit


struct UIScrollViewWrapper<Content: View>: UIViewControllerRepresentable {
    
    var content : () -> Content
    @Binding var bottomSheetIsOpen : Bool
    
    @Binding var dragOffsetPercentage : CGFloat
    
    func makeUIViewController(context: Context) -> UIScrollViewViewController {
        let vc = UIScrollViewViewController()
        vc.view.backgroundColor = .clear
        vc.scrollView.delegate = context.coordinator
        vc.scrollView.backgroundColor = .clear
        vc.hostingController.rootView = AnyView(self.content())
        return vc
    }
    
    func updateUIViewController(_ viewController: UIScrollViewViewController, context: Context) {
        viewController.hostingController.rootView = AnyView(self.content())
        if !bottomSheetIsOpen {
            if dragOffsetPercentage == 0 {
                if viewController.scrollView.contentOffset.y != 0 {
                    viewController.scrollView.setContentOffset(.zero, animated: false)
                }
            }
        }
    }
    
    class Coordinator : NSObject, UIScrollViewDelegate {
        
        var parent : UIScrollViewWrapper
        var requiredOffsetForDismissal : CGFloat = 72
        
        var lockingWiggleRoom : CGFloat = 6
        var locked : Bool = false
        
        init(_ parent : UIScrollViewWrapper) {
            self.parent = parent
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if scrollView.contentOffset.y <= lockingWiggleRoom {
                self.locked = false
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView.contentOffset.y <= lockingWiggleRoom {
                self.locked = false
            }
        }
        
        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            if scrollView.contentOffset.y <= lockingWiggleRoom {
                self.locked = false
            }
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if parent.bottomSheetIsOpen {
                if scrollView.contentOffset.y > lockingWiggleRoom {
                    self.locked = true
                }
                           
                if !locked {
                    if scrollView.contentOffset.y < 0 {
                        parent.dragOffsetPercentage = abs(scrollView.contentOffset.y)/(requiredOffsetForDismissal)
                    } else {
                        parent.dragOffsetPercentage = 0
                    }
                    
                    if scrollView.contentOffset.y <= -requiredOffsetForDismissal {
                        parent.bottomSheetIsOpen = false
                    }
                } else {
                    parent.dragOffsetPercentage = 0
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


class UIScrollViewViewController: UIViewController, UIScrollViewDelegate {
    lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.backgroundColor = .clear
        v.delegate = self
        return v
    }()
    
    var hostingController: UIHostingController<AnyView> = UIHostingController(rootView: AnyView(EmptyView()))
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.scrollView)
        self.pinEdges(of: self.scrollView, to: self.view)
        self.hostingController.willMove(toParent: self)
        self.hostingController.view.backgroundColor = .clear
        self.scrollView.addSubview(self.hostingController.view)
        self.pinEdges(of: self.hostingController.view, to: self.scrollView)
        self.hostingController.didMove(toParent: self)
    }
    
    func pinEdges(of viewA: UIView, to viewB: UIView) {
        viewA.translatesAutoresizingMaskIntoConstraints = false
        viewB.addConstraints([
            viewA.leadingAnchor.constraint(equalTo: viewB.leadingAnchor),
            viewA.trailingAnchor.constraint(equalTo: viewB.trailingAnchor),
            viewA.topAnchor.constraint(equalTo: viewB.topAnchor),
            viewA.bottomAnchor.constraint(equalTo: viewB.bottomAnchor),
        ])
    }
}
