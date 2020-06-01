//
//  NoiseView.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 01/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import UIKit

class NoiseView: UIView {
    
    var bw = false
    
    private let imgView = UIImageView()
    private var processing = false
    private var imgSize: CGSize = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imgView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window == nil {
            processing = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imgView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        imgSize = imgView.frame.size
        if !processing, frame.width > 0 {
            processing = true
            process()
        }
    }
    
    private func process() {
        if imgView.image == nil { doProcess() }
        else {
            DispatchQueue.global(qos: .userInteractive).async { self.doProcess() }
        }
    }
    
    private func doProcess() {
        UIGraphicsBeginImageContext(imgSize)
        if let context = UIGraphicsGetCurrentContext() {
            for x in 0 ..< Int(imgSize.width) {
                for y in 0 ..< Int(imgSize.height) {
                    if bw {
                        let c = Double.random(in: 0.0 ..< 1.0)
                        let color = UIColor(red: CGFloat(c), green: CGFloat(c), blue: CGFloat(c), alpha: 1.0)
                        context.setFillColor(color.cgColor)
                        context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                    else {
                        let r = Double.random(in: 0.0 ..< 1.0)
                        let g = Double.random(in: 0.0 ..< 1.0)
                        let b = Double.random(in: 0.0 ..< 1.0)
                        let color = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
                        context.setFillColor(color.cgColor)
                        context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                    
                }
            }
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        DispatchQueue.main.async { self.imgView.image = image }
        if processing {
            DispatchQueue.global(qos: .userInteractive).async { self.doProcess() }
        }
    }
    
}
