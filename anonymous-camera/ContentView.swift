//
//  ContentView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    @State var isRecording : Bool = false
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    Circle()
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                }
            }
            .padding()
            ACViewfinder(isRecording: $isRecording)
                .edgesIgnoringSafeArea(.all)
                .zIndex(1)
            
            if !isRecording {
                Spacer()
                HStack{
                    Spacer()
                    ACFilterSelector()
                    Spacer()
                }
                .transition(AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity))
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ACViewfinder: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    @Binding var isRecording : Bool
    
    internal var threeByFourAspectRatio : CGFloat = 3.0/4.0
    internal var sixteenByNineAspectRatio : CGFloat = 9.0/16.0
    
    var body: some View {
        ZStack {
            ACViewfinderCard(isRecording: $isRecording)
        }
    }
}

struct ACViewfinderCard : View {
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    @Binding var isRecording : Bool
    @State internal var shutterPosition : CGPoint = CGPoint.zero
    
    internal var threeByFourAspectRatio : CGFloat = 3.0/4.0
    internal var sixteenByNineAspectRatio : CGFloat = 9.0/16.0
    
    var body : some View {
        VStack {
            ZStack{
                ACViewfinderView()
                ZStack {
                    ForEach(anonymisation.faces) { (face) in
                        if !(self.anonymisation.selectedFilter?.modifiesImage ?? false) {
                            ACFaceRectangle()
                                .transition(AnyTransition.scale(scale: 0.75).combined(with: AnyTransition.opacity))
                                .frame(width: face.rect.width, height: face.rect.height, alignment: .center)
                                .animation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.72, blendDuration: 0))
                                .position(CGPoint(x: face.rect.minX, y: face.rect.minY))
                                .animation(nil)
                        }
                    }
                }
                .animation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.72, blendDuration: 0))
                
                GeometryReader { (geometry) in
                    ACViewfinderLandscapeContainer()
                        .frame(width: geometry.size.height, height: geometry.size.width, alignment: .center)
                        .rotationEffect(self.sceneInformation.deviceLandscapeRotationAngle)
                        .animation(self.sceneInformation.devicePreviousOrientationWasLandscape ? (Animation.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) : nil, value: self.sceneInformation.deviceLandscapeRotationAngle)
                }
            }
            .aspectRatio(isRecording ? sixteenByNineAspectRatio : threeByFourAspectRatio, contentMode: .fit)
            .foregroundColor(Color(UIColor.darkGray))
            .saturation(sceneInformation.sceneIsActive ? 1 : 0.5)
            .blur(radius: sceneInformation.sceneIsActive ? 0 : 48)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
            )
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
                .padding(0)
                .scaleEffect(sceneInformation.sceneIsActive ? 1 : 0.94)
                .animation(Animation.easeInOut(duration: 0.3), value: sceneInformation.sceneIsActive)
        }
    }
}

struct ACFaceRectangle : View {
    
    @State var isBeingTouched : Bool = false
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.clear)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(isBeingTouched ? 0.32 : 0.24), Color.white.opacity(isBeingTouched ? 0.64 : 0.48)]), startPoint: UnitPoint(x: 0.5, y: 0), endPoint: UnitPoint(x: 0.5, y: 1))
            )
        }
        .cornerRadius(percentage: 0.25, style: .continuous)
        .stroke(color: Color(UIColor(named: "highlight")?.withAlphaComponent(1) ?? .clear), lineWidth: 2, cornerPercentage: 0.25, style: .automatic)
        .opacity(self.anonymisation.selectedFilter?.modifiesImage ?? false ? 0 : 1)
        .scaleEffect(isBeingTouched ? 0.9 : 1)
        .shadow(color: Color(UIColor(named: "highlight")?.withAlphaComponent(0.25) ?? .clear), radius: 24, x: 0, y: 0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    withAnimation(.easeOut(duration: 0.08)) {
                        self.isBeingTouched = true
                    }
                })
                .onEnded({ _ in
                    withAnimation(.easeOut(duration: 0.24)) {
                        self.isBeingTouched = false
                    }
                })
        )
    }
}

struct ACFilterSelector: View {
    
    @EnvironmentObject var anonymisation : ACAnonymisation
    @EnvironmentObject var sceneInformation : ACScene
    
    let generator = UISelectionFeedbackGenerator()
    
    var body: some View {
        ZStack {
            HStack(spacing: sceneInformation.deviceOrientation.isLandscape ? 18 : 12){
                ForEach(anonymisation.filters) { filter in
                    ACFilterButton(filter: filter)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded({ _ in
                                    self.generator.selectionChanged()
                                    
                                    withAnimation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.72, blendDuration: 0)) {
                                        self.anonymisation.select(filter: filter)
                                    }
                                })
                    )}
            }
        }
        .animation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.72, blendDuration: 0))
    }
}

struct ACFilterButton: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @State internal var isBeingTouched : Bool = false
    var filter : ACFilter
    
    var body: some View {
        HStack (alignment: .center) {
            
            if filter.filterIdentifier == "AC_FILTER_NONE" {
                
                ACNoFilterIconView()
                    .frame(width: 24, height: 24, alignment: .center)
                
            } else if filter.filterIdentifier == "AC_FILTER_BLUR" {
                
                ACBlurFilterIconView()
                .frame(width: 24, height: 24, alignment: .center)
            
            } else {
                Image(uiImage: filter.icon)
                    .foregroundColor(
                        filter.selected ? (filter.modifiesImage ? Color(.black) : Color(.systemBackground)) : Color(.label)
                )
                .rotationEffect(sceneInformation.deviceRotationAngle)
                .animation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.6, blendDuration: 0))
            }
                        
            if (filter.selected && !sceneInformation.deviceOrientation.isLandscape) {
                Text(filter.name)
                    .font(Font.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(
                        filter.selected ? (filter.modifiesImage ? Color(.black) : Color(.systemBackground)) : Color(.label)
                )
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .transition(AnyTransition.scale(scale: 0.5, anchor: UnitPoint(x: 0, y: 0.5)).combined(with: AnyTransition.opacity))
            }
        }
        .padding(18)
        .mask(
            HStack(spacing: 0) {
                Rectangle()
                    .foregroundColor(Color(UIColor.systemPink))
                LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemPink), Color(UIColor.systemPink.withAlphaComponent(0))]), startPoint: UnitPoint(x: 0, y: 0.5), endPoint: UnitPoint(x: 1, y: 0.5))
                    .frame(width: 16)
            }
        )
            .background(
                filter.selected ? (filter.modifiesImage ? Color("highlight") : Color(.label)) : (isBeingTouched ? Color(.label).opacity(0.75) : Color(.label).opacity(0.25))
        )
            .clipShape(RoundedRectangle(cornerRadius: 100, style: .circular))
            .scaleEffect(isBeingTouched ? 0.92 : 1)
            .scaleEffect(sceneInformation.deviceOrientation.isLandscape ? (filter.selected ? 1.12 : 1) : 1)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        withAnimation(.easeOut(duration: 0.08)) {
                            self.isBeingTouched = true
                        }
                    })
                    .onEnded({ _ in
                        withAnimation(.easeOut(duration: 0.24)) {
                            self.isBeingTouched = false
                        }
                    })
        )
    }
}

struct ACViewfinderLandscapeContainer: View {    
    var body: some View {
        GeometryReader { outerGeometry in
            ZStack {
                ACInterviewModeContainerView()
            }
        }
    }
}
