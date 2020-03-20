//
//  Helpers.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 19/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import SnapKit

class AAView : UIView {

    private let containerView = UIView()
    private var backgroundMaterialView = UIVisualEffectView()
    private var backgroundColorView = UIView()
    var contentView = UIView()
    var vibrantContentView = UIVisualEffectView()

    var contentViewRespectsSafeAreaLayoutGuide : Bool = false {
        didSet {
            if contentViewRespectsSafeAreaLayoutGuide {
                contentView.snp.remakeConstraints { make in
                    make.pinAllEdges(withInsets: nil, respectingSafeAreaLayoutGuidesOfView: self)
                }
            } else {
                contentView.snp.remakeConstraints { make in
                    make.pinAllEdgesToSuperView()
                }
            }
        }
    }
    
    private var cornerCurve : CALayerCornerCurve = .circular
    
    private var cornerRad : Float? {
        didSet {
            if let radius = cornerRad {
                self.adjustCornerRadius(withRadius: radius, andCornerCurve: cornerCurve)
            } else {
                if cornerPercentage == 0 || cornerPercentage == nil {
                    self.containerView.layer.masksToBounds = false
                    self.containerView.layer.cornerRadius = 0
                }
            }
        }
    }

    private var cornerPercentage : Float? {
        didSet {
            if let percentage = cornerPercentage {
                self.adjustCornerRadius(withPercentage: percentage, andCornerCurve: cornerCurve)
            } else {
                if cornerRadius == 0 || cornerRad == nil {
                    self.containerView.layer.masksToBounds = false
                    self.containerView.layer.cornerRadius = 0
                }
            }
        }
    }
    
    func position () -> CGPoint {
        return self.convert(self.center, to: nil)
    }

    func size () -> CGSize {
        return self.frame.size
    }
    
    init () {
        super.init(frame: CGRect.zero)

        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.accessibilityIdentifier = "AAView/containerView"
        self.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }

        containerView.addSubview(backgroundMaterialView)
        backgroundMaterialView.accessibilityIdentifier = "AAView/backgroundMaterialView"
        backgroundMaterialView.backgroundColor = .clear
        backgroundMaterialView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        containerView.addSubview(backgroundColorView)
        backgroundColorView.accessibilityIdentifier = "AAView/backgroundColorView"
        backgroundColorView.backgroundColor = nil
        backgroundColorView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }

        containerView.addSubview(contentView)
        contentView.accessibilityIdentifier = "AAView/contentView"
        contentView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }

        backgroundMaterialView.contentView.translatesAutoresizingMaskIntoConstraints = false
        backgroundMaterialView.contentView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }

        backgroundMaterialView.contentView.addSubview(vibrantContentView)
        vibrantContentView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }

        vibrantContentView.contentView.translatesAutoresizingMaskIntoConstraints = false
        vibrantContentView.accessibilityIdentifier = "AAView/vibrantContentView"
        vibrantContentView.contentView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
    }

    private func adjustCornerRadius (withPercentage percentage : Float?, andCornerCurve cornerCurve : CALayerCornerCurve) {
        if let p = percentage {
            if p == 1 {
                self.containerView.layer.masksToBounds = true
                self.containerView.layer.cornerCurve = cornerCurve
                self.containerView.layer.cornerRadius = min(bounds.width, bounds.height) / 2
            } else {
                self.containerView.layer.masksToBounds = true
                self.containerView.layer.cornerCurve = cornerCurve
                self.containerView.layer.cornerRadius = min(bounds.width, bounds.height) * (CGFloat(p)/2)
            }
        } else {
            self.containerView.layer.masksToBounds = false
            self.containerView.layer.cornerRadius = 0
        }
    }


    private func adjustCornerRadius (withRadius radius : Float?, andCornerCurve cornerCurve : CALayerCornerCurve) {
        if let r = radius {
            if r == Float.infinity {
                self.containerView.layer.masksToBounds = true
                self.containerView.layer.cornerRadius = min(bounds.width, bounds.height) / 2
            } else {
                self.containerView.layer.masksToBounds = true
                self.containerView.layer.cornerRadius = CGFloat(r)
            }
        } else {
            self.containerView.layer.masksToBounds = false
            self.containerView.layer.cornerRadius = 0
        }
    }
    
    func configureBackground (withColor color : UIColor?, andMaterial material : UIBlurEffect.Style?) {
        
        if let c = color {
            backgroundColorView.backgroundColor = c
        } else {
            backgroundColorView.backgroundColor = .clear
        }
        
        if let m = material {
            backgroundMaterialView.effect = UIBlurEffect(style: m)
        } else {
            backgroundMaterialView.effect = nil
        }
    }
    
    func configureCorner (withRadius radius : Float, andCornerCurve cornerCurve : CALayerCornerCurve) {
        self.cornerCurve = cornerCurve
        self.cornerPercentage = nil
        self.cornerRad = radius
    }
    
    func configureCorner (withPercentage percentage : Float, andCornerCurve cornerCurve : CALayerCornerCurve) {
        self.cornerCurve = cornerCurve
        self.cornerRad = nil
        self.cornerPercentage = percentage
    }

    func configureShadow (withColor color: UIColor, radius : CGFloat, opacity: Float, andOffset offset : CGSize) {
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowColor = color.cgColor
    }
    
    func configureBorder (withColor color: UIColor, width : CGFloat) {
        containerView.layer.borderColor = color.cgColor
        containerView.layer.borderWidth = width
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let r = cornerRad {
            self.adjustCornerRadius(withRadius: Float(r), andCornerCurve: cornerCurve)
        }

        if let p = cornerPercentage {
            self.adjustCornerRadius(withPercentage: p, andCornerCurve: cornerCurve)
        }
    }
}

class AALabel : UILabel {
    
    var lineHeightMultiple : Float = 1 {
        didSet {
            self.setTextWithAttributes(text: self.text)
        }
    }
    
    var letterSpacing : Float? {
        didSet {
            self.setTextWithAttributes(text: self.text)
        }
    }
    
    var uppercased : Bool = false {
        didSet {
            self.setTextWithAttributes(text: self.text)
        }
    }
    
    override var text: String? {
        didSet {
            self.setTextWithAttributes(text: self.text)
        }
    }
    
    init () {
        super.init(frame: CGRect.zero)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setTextWithAttributes (text : String?) {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = CGFloat(lineHeightMultiple)
        
        let t = uppercased ? text?.uppercased() : text;
        
        let attributedString = NSMutableAttributedString(string: t ?? "")
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle, NSAttributedString.Key.kern : CGFloat(letterSpacing ?? 0)], range: NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ConstraintMaker {
    func everythingEqualToSuperView () {
        self.size.equalToSuperview()
        self.center.equalToSuperview()
    }
    
    func pinAllEdges (withInsets insets: UIEdgeInsets?, respectingSafeAreaLayoutGuidesOfView view : UIView?) {
        let insets = insets ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        if let v = view {
            self.top.equalTo(v.safeAreaLayoutGuide.snp.top).inset(insets)
            self.bottom.equalTo(v.safeAreaLayoutGuide.snp.bottom).inset(insets)
            self.leading.equalTo(v.safeAreaLayoutGuide.snp.leading).inset(insets)
            self.trailing.equalTo(v.safeAreaLayoutGuide.snp.trailing).inset(insets)
        } else {
            self.top.equalToSuperview().inset(insets)
            self.bottom.equalToSuperview().inset(insets)
            self.left.equalToSuperview().inset(insets)
            self.right.equalToSuperview().inset(insets)
        }
    }
    
    func pinAllEdgesToSuperView () {
        self.top.equalToSuperview()
        self.left.equalToSuperview()
        self.right.equalToSuperview()
        self.bottom.equalToSuperview()
    }
}

extension UIFont {
    
    static func roundedSystemFont (ofSize fontSize : CGFloat, andWeight weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: weight)
        
        var font: UIFont = systemFont
        
        if #available(iOS 13.0, *) {
            if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: descriptor, size: fontSize)
            }
        }
        
        return font
    }
    
    func fontWithFeature(key: Int, value:Int) -> UIFont {
        let originalDesc = self.fontDescriptor
        let features:[UIFontDescriptor.AttributeName: Any] = [
            UIFontDescriptor.AttributeName.featureSettings : [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: key,
                    UIFontDescriptor.FeatureKey.typeIdentifier: value
                ]
            ]
        ]
        let newDesc = originalDesc.addingAttributes(features)
        return UIFont(descriptor: newDesc, size: 0.0)
    }
    
    func fontWithVerticallyCenteredColon() -> UIFont {
        return self.fontWithFeature(key: kStylisticAlternativesType, value: kStylisticAltThreeOnSelector)
    }
    
    func fontWithSlashedZero() -> UIFont {
        return self.fontWithFeature(key: kTypographicExtrasType, value: kSlashedZeroOnSelector)
    }
    
    func fontWithMonospacedNumbers() -> UIFont {
        return self.fontWithFeature(key: kNumberSpacingType, value: kMonospacedNumbersSelector)
    }
    
    func fontWithHighLegibility() -> UIFont {
        return self.fontWithFeature(key: kStylisticAlternativesType, value: kStylisticAltSixOnSelector)
    }
}

extension UISpringTimingParameters {
    public convenience init(dampingRatio: CGFloat, frequencyResponse: CGFloat) {
        precondition(dampingRatio >= 0)
        precondition(frequencyResponse > 0)
        
        let mass = 1 as CGFloat
        let stiffness = pow(2 * .pi / frequencyResponse, 2) * mass
        let damping = 4 * .pi * dampingRatio * mass / frequencyResponse
        
        self.init(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: .zero)
    }
}


struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct CornerRadiusAndStyleModifier: ViewModifier {
    
    var radius : CGFloat = 0
    var style : CornerStyle = .circular
    
    func body(content: Content) -> some View {
        if style == .automatic {
            if radius == 1 {
                return content
                    .clipShape(
                        RoundedRectangle(cornerRadius: self.radius, style: .circular)
                )
            } else {
                return content
                    .clipShape(
                        RoundedRectangle(cornerRadius: self.radius, style: .continuous)
                )
            }
        } else if style == .continuous {
            return content
                .clipShape(
                    RoundedRectangle(cornerRadius: self.radius, style: .continuous)
            )
        } else {
            return content
                .clipShape(
                    RoundedRectangle(cornerRadius: self.radius, style: .circular)
            )
        }
    }
}

struct ViewStrokeModifierWithRadius: ViewModifier {
    
    var color : Color = .clear
    var lineWidth : CGFloat = 1
    var cornerRadius : CGFloat = 0
    var style : CornerStyle = .circular
    
    func body(content: Content) -> some View {
        if style == .automatic {
            if cornerRadius == 1 {
                return content
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                        .stroke(color, lineWidth: lineWidth)
                )
            } else {
                return content
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(color, lineWidth: lineWidth)
                )
            }
        } else if style == .continuous {
            return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: lineWidth)
            )
        } else {
            return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                    .stroke(color, lineWidth: lineWidth)
            )
        }
    }
}

struct ViewStrokeModifierWithPercentage: ViewModifier {
    
    var color : Color = .clear
    var lineWidth : CGFloat = 1
    var cornerPercentage : CGFloat = 0
    var style : CornerStyle = .circular
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
            .stroke(color: self.color, lineWidth: self.lineWidth, cornerRadius: (CGFloat.minimum(geometry.size.width, geometry.size.height)/2)*self.cornerPercentage, style: self.style)
        }
    }
}

struct CornerPercentageAndStyleModifier: ViewModifier {
    
    var percentage : CGFloat = 1
    var style : CornerStyle = .circular
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .cornerRadius(radius: (CGFloat.minimum(geometry.size.width, geometry.size.height)/2)*self.percentage, style: self.style)
        }
    }
}

enum CornerStyle {
    case circular
    case continuous
    case automatic
}

extension View {
    func cornerRadius(radius : CGFloat, style : CornerStyle) -> some View {
        self.modifier(CornerRadiusAndStyleModifier(radius: radius, style: style))
    }
    func cornerRadius(percentage : CGFloat, style : CornerStyle) -> some View {
        self.modifier(CornerPercentageAndStyleModifier(percentage: percentage, style: style))
    }
    func stroke(color: Color, lineWidth: CGFloat, cornerRadius: CGFloat, style: CornerStyle) -> some View {
        self.modifier(ViewStrokeModifierWithRadius(color: color, lineWidth: lineWidth, cornerRadius: cornerRadius, style: style))
    }
    func stroke(color: Color, lineWidth: CGFloat, cornerPercentage: CGFloat, style: CornerStyle) -> some View {
        self.modifier(ViewStrokeModifierWithPercentage(color: color, lineWidth: lineWidth, cornerPercentage: cornerPercentage, style: style))
    }
}
