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
    
    @Binding var isRecording : Bool
    @Binding var locked : Bool

        
    var body: some View {
        ZStack {
            
            ACShutterProgressIndicator(isRecording: $isRecording)
            .opacity(isRecording ? 1 : 0)
                .offset(
                    
                    x:
                    withAnimation(Animation.spring(), {
                        isRecording ? sceneInformation.deviceOrientation.isLandscape ? (locked ? -88 : 0) : 0 : 0
                    })
                    ,y:
                    withAnimation(Animation.spring(), {
                        isRecording ? sceneInformation.deviceOrientation.isLandscape ? (locked ? 0 : -88) : -88 : 0
                    })
            )
            .rotationEffect(sceneInformation.deviceRotationAngle)
            
            Circle()
            .foregroundColor(.white)
            .frame(width: 70, height: 70, alignment: .center)
                .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 0)
            
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
    
    @Binding var isRecording : Bool
            
    var body: some View {
        Text(anonymisation.timeCode)
            .font(Font.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
        .foregroundColor(Color.black)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
