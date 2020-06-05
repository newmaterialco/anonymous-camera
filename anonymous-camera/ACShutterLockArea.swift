//
//  ACShutterLockArea.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 03/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ACShutterLockArea: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    @Binding var isRecording : Bool
    @Binding var hovering : Bool
    @Binding var locked : Bool
    
    var body: some View {
        ZStack {
            Circle()
            .foregroundColor(Color.white.opacity(0.75))
            .frame(width: 70, height: 70, alignment: .center)
            .scaleEffect((hovering && isRecording && !locked) ? 1.5 : 1)
            Image(uiImage: UIImage(named: (hovering && isRecording && !locked) ? "AC_GLYPH_LOCKED" : "AC_GLYPH_UNLOCKED")!)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color(UIColor.black))
                .rotationEffect(self.sceneInformation.deviceRotationAngle)
        }
    }
}
