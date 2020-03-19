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
            Spacer()
            ACViewfinder(isRecording: $isRecording)
                .edgesIgnoringSafeArea(.all)
                .zIndex(1)
            
            if !isRecording {
                Spacer()
                ACFilterSelector()
                    .transition(AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity))
            }
            Spacer()
        }
        .coordinateSpace(name: "test")
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
    @State internal var shutterPosition : CGPoint = CGPoint.zero
    
    internal var threeByFourAspectRatio : CGFloat = 3.0/4.0
    internal var sixteenByNineAspectRatio : CGFloat = 9.0/16.0
    
    var body: some View {
        ZStack {
            ZStack{
                ACViewfinderView()
                    .saturation(sceneInformation.sceneIsActive ? 1 : 0)
                    .blur(radius: sceneInformation.sceneIsActive ? 0 : 100)
                    .animation(Animation.easeInOut, value: sceneInformation.sceneIsActive)
                
                GeometryReader { (geometry) in
                    ACViewfinderLandscapeContainer()
                        .background(Color.yellow.opacity(0.25))
                        .frame(width: geometry.size.height, height: geometry.size.width, alignment: .center)
                        .rotationEffect(self.sceneInformation.deviceLandscapeRotationAngle)
                        .animation(self.sceneInformation.devicePreviousOrientationWasLandscape ? (Animation.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) : nil, value: self.sceneInformation.deviceLandscapeRotationAngle)
                }
                
                ZStack {
                    ForEach(anonymisation.faces) { (face) in
                        RoundedRectangle(cornerRadius: 24, style: .circular)
                            .foregroundColor(.yellow)
                            .frame(width: face.rect.width, height: face.rect.height, alignment: .center)
                            .position(CGPoint(x: face.rect.minX, y: face.rect.minY))
                            .transition(
                                AnyTransition.scale(scale: 0.5, anchor: UnitPoint(x: 0.5, y: 0.5)).combined(with: AnyTransition.opacity)
                            )
                        
                        Text("\(face.rect.minY)")
                            .foregroundColor(.white)
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Rectangle()
                            .frame(width: 0, height: 0, alignment: .center)
                    }
                    .frame(width: 72, height: 72)
                    .background(Color.red)
                    .padding()
                    .position(shutterPosition)
                    .coordinateSpace(name: "test")
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("test"))
                            .onChanged({ value in
                                withAnimation(Animation.interactiveSpring(response: 0.4, dampingFraction: 0.9, blendDuration: 0)) {
                                    self.isRecording = true
                                }
                                
                                self.shutterPosition = value.location
                            })
                            .onEnded({ value in
                                withAnimation(Animation.interactiveSpring(response: 0.4, dampingFraction: 0.9, blendDuration: 0)) {
                                    self.isRecording = false
                                }
                                
                                self.shutterPosition = CGPoint.zero
                            })
                    )
                }
            }
            .aspectRatio(isRecording ? sixteenByNineAspectRatio : threeByFourAspectRatio, contentMode: .fit)
            .foregroundColor(Color(UIColor.darkGray))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
            )
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
                .padding(0)
        }
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
    }
}

struct ACFilterButton: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @State internal var isBeingTouched : Bool = false
    var filter : ACFilter
    
    var body: some View {
        HStack (alignment: .center) {
            Image(uiImage: filter.icon)
                .foregroundColor(
                    filter.selected ? (filter.modifiesImage ? Color(.black) : Color(.systemBackground)) : Color(.label)
            )
                .rotationEffect(sceneInformation.deviceRotationAngle)
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
    @EnvironmentObject var sceneInformation : ACScene
    @State internal var isBeingTouched : Bool = false
    @State internal var interviewModeDraggableOffset : CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack (alignment: .center) {
                Spacer()
                HStack (alignment: .bottom) {
                    Text("Interview")
                        .font(Font.system(size: 16, weight: .semibold, design: .default))
                }
                .frame(alignment: .bottom)
                .padding()
                .background(Blur(style: .systemChromeMaterialLight))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding()
                .scaleEffect(self.isBeingTouched ? 0.9 : 1)
                .offset(y: self.sceneInformation.deviceOrientation.isLandscape ? 0 : 200)
                .offset(x: self.interviewModeDraggableOffset)
                .animation(Animation.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: self.sceneInformation.deviceOrientation.isLandscape)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged({ value in
                            self.interviewModeDraggableOffset = value.translation.width
                            withAnimation(.easeOut(duration: 0.12)) {
                                self.isBeingTouched = true
                            }
                        })
                        .onEnded({ _ in
                            withAnimation(.easeOut(duration: 0.24)) {
                                self.isBeingTouched = false
                            }
                        })
                )
                    .background(Color.blue)
            }
        }
    }
}

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
