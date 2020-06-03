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

    
    var body: some View {
        Circle()
        .stroke(Color.white)
        .frame(width: 70, height: 70, alignment: .center)
        .scaleEffect(hovering ? 1.5 : 1)
    }
}
