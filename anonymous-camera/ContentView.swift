//
//  ContentView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var settings = ACSettingsStore()
            
    var body: some View {
        
        VStack {
            ACViewfinder()
            ACFilterSelector(settings: settings)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ACViewfinder: View {
    var body: some View {
        ZStack {
            ZStack{
                ACViewfinderView()
                .aspectRatio(0.75, contentMode: .fit)
            }
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
    
    let generator = UISelectionFeedbackGenerator()
        
    var body: some View {
        ZStack {
            HStack{
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
    
    
    @State internal var isBeingTouched : Bool = false
    var filter : ACFilter

    var body: some View {
        HStack {
            Image(uiImage: filter.icon)
                .foregroundColor(
                    filter.selected ? (filter.modifiesImage ? Color(.black) : Color(.systemBackground)) : Color(.label)
                )
            if filter.selected {
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
        .clipShape(RoundedRectangle(cornerRadius: 100, style: .circular)
        )
        .scaleEffect(isBeingTouched ? 0.9 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    withAnimation(.easeIn(duration: 0.12)) {
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
