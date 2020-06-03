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
        
    var body: some View {
        ZStack {
            
            ACShutterProgressIndicator(isRecording: $isRecording)
            .opacity(isRecording ? 1 : 0)
                .offset(y:
                    withAnimation(Animation.spring(), {
                        isRecording ? -88 : 0
                    })
            )
            .rotationEffect(sceneInformation.deviceRotationAngle)
            
            Circle()
            .foregroundColor(.white)
            .frame(width: 70, height: 70, alignment: .center)
        }
    }
}

struct ACShutterProgressIndicator: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    @Binding var isRecording : Bool
        
    var body: some View {
        Text(anonymisation.timeCode)
            .font(Font.system(size: 12, weight: .semibold, design: .default).monospacedDigit())
        .foregroundColor(Color.black)
        .padding()
        .background(Color.white)
    }
}
