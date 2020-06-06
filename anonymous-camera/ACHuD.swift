//
//  ACHuD.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 03/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ACHuD: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    var body: some View {
        HStack {
            if self.sceneInformation.hudLoading {
                ActivityIndicator(shouldAnimate: self.$sceneInformation.hudLoading)
                .transition(AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.75)))
            }
            if self.sceneInformation.hudIcon != nil {
                Image(uiImage: self.sceneInformation.hudIcon!.withRenderingMode(.alwaysTemplate))
                .resizable()
                .foregroundColor(Color(self.sceneInformation.hudTint))
                .frame(width: 18, height: 18)
                .transition(AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.75)))
            }
            Text(self.sceneInformation.hudString.uppercased())
            .font(Font.system(size: 16).uppercaseSmallCaps())
            .foregroundColor(Color(self.sceneInformation.hudTint))
            .fixedSize(horizontal: true, vertical: true)
            .frame(minHeight: 18)
        }
        .animation(nil)
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct ACHuD_Previews: PreviewProvider {
    static var previews: some View {
        ACHuD()
    }
}

struct ActivityIndicator: UIViewRepresentable {
    @Binding var shouldAnimate: Bool
    @EnvironmentObject var sceneInformation : ACScene
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.style = .medium
        return indicatorView
    }

    func updateUIView(_ uiView: UIActivityIndicatorView,
                      context: Context) {
        uiView.color = sceneInformation.hudTint
        if self.shouldAnimate {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}
