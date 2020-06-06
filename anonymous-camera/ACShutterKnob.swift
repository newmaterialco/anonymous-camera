//
//  ACShutterKnob.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 02/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import Foundation
import SwiftUI

struct ACShutterKnob: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    @Binding var locked : Bool
        
    
    var body: some View {
        ZStack {
            
            ACShutterProgressIndicator()
                .opacity(self.sceneInformation.isVideoRecording ? 1 : 0)
                .offset(
                    x:
                        self.sceneInformation.isVideoRecording ? sceneInformation.deviceOrientation.isLandscape ? (locked ? -88 : 0) : 0 : 0
                    ,y:
                        self.sceneInformation.isVideoRecording ? sceneInformation.deviceOrientation.isLandscape ? (locked ? 0 : -88) : -88 : 0
            )
            .animation(Animation.spring())
            .rotationEffect(sceneInformation.deviceRotationAngle)
            
            Circle()
                .foregroundColor(.white)
                .frame(width: 70, height: 70, alignment: .center)
                .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 0)
                .animation(Animation.interactiveSpring())
            
            if locked {
                Image(uiImage: UIImage(named: "stop")!)
                    .foregroundColor(Color(UIColor.black))
                    .transition(AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.75)))
            }
        }
    }
}

struct ACShutterProgressIndicator: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    var body: some View {
        HStack (spacing: 4) {
            Circle()
                .frame(width: 12, height: 12)
                .foregroundColor(Color.red)
                Text(anonymisation.timeCode)
                .font(Font.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundColor(Color(self.sceneInformation.hudTint))
                .fixedSize(horizontal: true, vertical: true)
                .frame(height: 18)
                .foregroundColor(Color.black)
                .animation(nil)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}
