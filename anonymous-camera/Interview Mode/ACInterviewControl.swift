//
//  ACInterviewControl.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ACInterviewControl: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    @State internal var isBeingTouched : Bool = false
    
    let generator = UISelectionFeedbackGenerator()
    
    var body: some View {
        ZStack{
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(self.anonymisation.interviewModeIsOn ? 0.24 : 0.12), Color.black.opacity(self.anonymisation.interviewModeIsOn ? 0.24 : 0), Color.black.opacity(self.anonymisation.interviewModeIsOn ? 0.24 : 0.12)]), startPoint: UnitPoint(x: 0.5, y: 0), endPoint: UnitPoint(x: 0.5, y: 1))
                .clipShape(RoundedRectangle(cornerRadius: self.anonymisation.interviewModeIsOn ? 0.5 : 0, style: .continuous))
                .frame(width: 1, alignment: .center)
                .frame(maxHeight: .infinity)
                .padding(self.anonymisation.interviewModeIsOn ? 12 : 0)
            
            if !self.anonymisation.interviewModeIsOn {
                Text("Split")
                    .font(Font.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.black)
                    .transition(AnyTransition.scale(scale: 0.75, anchor: UnitPoint(x: 0.5, y: 0.5)).combined(with: AnyTransition.opacity))
            }
            
            HStack (alignment: .center) {
                Image(uiImage: UIImage(named: "AC_FILTER_NONE_ICON")!)
                    .foregroundColor(Color.black)
                    .rotationEffect(self.anonymisation.interviewModeEffectsSwitched ? Angle(degrees: 180) : Angle(degrees: 0))
                
                if !self.anonymisation.interviewModeIsOn {
                    Text("Split")
                        .font(Font.system(size: 14, weight: .semibold, design: .default))
                        .opacity(0)
                }
                
                VStack {
                    if self.anonymisation.selectedFilter?.filterIdentifier == "AC_FILTER_PIXEL" {
                        Image(uiImage: UIImage(named: "AC_FILTER_PIXEL_ICON")!)
                            .foregroundColor(Color.black)
                            .rotationEffect(self.anonymisation.interviewModeEffectsSwitched ? Angle(degrees: 180) : Angle(degrees: 0))
                    } else  {
                        Image(uiImage: UIImage(named: "AC_FILTER_BLUR_ICON")!)
                            .foregroundColor(Color.black)
                            .rotationEffect(self.anonymisation.interviewModeEffectsSwitched ? Angle(degrees: 180) : Angle(degrees: 0))
                    }
                }
            }
            .padding()
            .rotationEffect(self.anonymisation.interviewModeEffectsSwitched ? Angle(degrees: 180) : Angle(degrees: 0))
        }
        .background(
            ZStack {
                Blur(style: .systemChromeMaterialLight)
                Color.white.opacity(self.anonymisation.interviewModeIsOn ? 1 : 0)
            }
        )
        .clipShape(
            RoundedRectangle(cornerRadius: self.anonymisation.interviewModeIsOn ? 42 : 12, style: self.anonymisation.interviewModeIsOn ? .circular : .continuous)
        )
        .scaleEffect(self.isBeingTouched ? 0.9 : 1)
        .offset(y: self.sceneInformation.deviceOrientation.isLandscape ? 0 : 200)
        .shadow(color: Color(UIColor.black.withAlphaComponent(self.anonymisation.interviewModeIsOn ? 0.24 : 0.12)), radius: 18, x: 0, y: 0)
        .animation(Animation.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: self.sceneInformation.deviceOrientation.isLandscape)
        .animation(Animation.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: self.anonymisation.interviewModeIsOn)
        .simultaneousGesture(
            TapGesture()
                .onEnded({ _ in
                                        
                    if self.anonymisation.interviewModeIsOn {
                        withAnimation(Animation.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                            self.anonymisation.switchEffectsInInterviewMode()
                        }
                    } else {
                        self.generator.selectionChanged()
                        self.anonymisation.interviewModeConfiguration = .effectTrailing
                    }
                })
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("landscapeContainer"))
                .onChanged({ value in
                    withAnimation(.easeOut(duration: 0.12)) {
                        self.isBeingTouched = true
                    }
                })
                .onEnded({ _ in
                    withAnimation(.easeOut(duration: 0.24)) {
                        self.isBeingTouched = false
                        self.sceneInformation.interviewModeControlIsBeingTouched = false
                    }
                })
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2, maximumDistance: 0)
                .onEnded({ _ in
                    withAnimation(.easeOut(duration: 0.12)) {
                        if self.anonymisation.interviewModeIsOn {
                            self.sceneInformation.interviewModeControlIsBeingTouched = true
                        }
                    }
                })
        )
    }
}
