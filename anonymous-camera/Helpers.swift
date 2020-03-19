//
//  Helpers.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 19/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import Foundation
import SwiftUI

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
