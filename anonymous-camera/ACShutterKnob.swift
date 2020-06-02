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
            Circle()
            .foregroundColor(.white)
            
            ACShutterProgressIndicator(isRecording: $isRecording)
            .offset(y: -100)
            .rotationEffect(sceneInformation.deviceRotationAngle)
        }
        .frame(width: 70, height: 70)
    }
}

struct ACShutterProgressIndicator: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    @Binding var isRecording : Bool
        
    var body: some View {
        Text("00:00")
    }
}
