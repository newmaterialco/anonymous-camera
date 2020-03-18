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
    @ObservedObject var settings = ACSettingsStore()
            
    var body: some View {
                
        VStack {
            Spacer()
            ACViewfinder()
            Spacer()
            ACFilterSelector(settings: settings)
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
    
    var body: some View {
        ZStack {
            ZStack{
                ACViewfinderView()
                .aspectRatio(0.75, contentMode: .fit)
                .blur(radius: sceneInformation.sceneIsActive ? 0 : 100)
                .animation(Animation.easeInOut, value: sceneInformation.sceneIsActive)
                
                GeometryReader { (geometry) in
                    ACViewfinderLandscapeContainer()
                    .frame(width: geometry.size.height, height: geometry.size.width, alignment: .bottom)
                    .rotationEffect(self.sceneInformation.deviceLandscapeRotationAngle)
                    .animation(self.sceneInformation.devicePreviousOrientationWasLandscape ? (Animation.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) : nil, value: self.sceneInformation.deviceLandscapeRotationAngle)
                }
            }
            .aspectRatio(0.75, contentMode: .fit)
            .foregroundColor(Color(UIColor.darkGray))
            .clipShape(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .padding(0)
        }
    }
}

struct ACFilterSelector: View {
    
    @ObservedObject var settings : ACSettingsStore
    @EnvironmentObject var sceneInformation : ACScene

    let generator = UISelectionFeedbackGenerator()
        
    var body: some View {
        ZStack {
            HStack(spacing: sceneInformation.deviceOrientation.isLandscape ? 18 : 12){
                ForEach(settings.filters) { filter in
                    ACFilterButton(filter: filter)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded({ _ in
                                    self.generator.selectionChanged()
                                    self.settings.select(filter: filter)
                                })
                    )}
            }
            .animation(
                Animation.interactiveSpring(response: 0.4, dampingFraction: 0.69, blendDuration: 0)
            )
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
            filter.selected ? (filter.modifiesImage ? Color("highlight") : Color(.label)) : Color(.label).opacity(0.12)
        )
        .clipShape(RoundedRectangle(cornerRadius: 100, style: .circular))
        .scaleEffect(isBeingTouched ? 0.9 : 1)
        .scaleEffect(sceneInformation.deviceOrientation.isLandscape ? (filter.selected ? 1.12 : 1) : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
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
    }
}

struct ACViewfinderLandscapeContainer: View {
    @EnvironmentObject var sceneInformation : ACScene
    @State internal var isBeingTouched : Bool = false

    var body: some View {
        ZStack {
            HStack {
                Text("Interview")
                .font(Font.system(size: 16, weight: .semibold, design: .default))
            }
            .padding()
            .background(Blur(style: .systemChromeMaterialLight))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding()
            .scaleEffect(isBeingTouched ? 0.9 : 1)
            .offset(y: sceneInformation.deviceOrientation.isLandscape ? 0 : 200)
            .animation(Animation.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: sceneInformation.deviceOrientation.isLandscape)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
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
