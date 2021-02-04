//
//  PGInteractiveLogo.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 29/07/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct PGInteractiveLogo: View {
        @State var angle: Double = 0.0
        @State var isAnimating = false
        @State var globalDragPosition : CGPoint = CGPoint.zero
        
        @GestureState private var isTouched = false
        @State var containerTouched = false
        
        @State var isTapped = false
            
        var foreverAnimation: Animation {
            Animation.linear(duration: 12.0)
                .repeatForever(autoreverses: false)
        }
        
        var slowForeverAnimation: Animation {
            Animation.linear(duration: 36.0)
                .repeatForever(autoreverses: false)
        }
        
        
        var body: some View {
            
            Button(action: {
                if let url = URL(string: "https://www.playground.ai") {
                   UIApplication.shared.open(url)
               }
            }, label: {
                HStack (spacing: 0) {
                    LetterContainer(up: false, imageName: "playground-0", globalDragPosition: $globalDragPosition)
                    LetterContainer(up: false, imageName: "playground-1", globalDragPosition: $globalDragPosition)
                    LetterContainer(up: false, imageName: "playground-2", globalDragPosition: $globalDragPosition)
                    LetterContainer(up: false, imageName: "playground-3", globalDragPosition: $globalDragPosition)
                    LetterContainer(up: true, imageName: "playground-4", globalDragPosition: $globalDragPosition)
                    LetterContainer(up: true, imageName: "playground-5", globalDragPosition: $globalDragPosition)
                    Image("gradient")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 16, height: 16, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .hueRotation(Angle(degrees: self.isAnimating ? 360.0 : 0.0))
                        .animation(self.foreverAnimation)
                        .rotationEffect(Angle(degrees: self.isAnimating ? 360.0 : 0.0), anchor: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .animation(self.slowForeverAnimation)
                        .onAppear {
                            self.isAnimating = true
                        }
                        .clipShape(Circle())
                        .scaleEffect(isTapped || isTouched ? 0.88 : 1, anchor: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .offset(y: -6.5)
                    LetterContainer(up: true, imageName: "playground-7", globalDragPosition: $globalDragPosition)
                    LetterContainer(up: true, imageName: "playground-8", globalDragPosition: $globalDragPosition)
                    LetterContainer(up: true, imageName: "playground-9", globalDragPosition: $globalDragPosition)
                }
                .frame(height: 42, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(
                    self.isTapped || isTouched ? Color.gray.opacity(0.12) : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .scaleEffect(self.isTapped || isTouched ? 0.96 : 1, anchor: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .animation(.interactiveSpring())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .global)
                        .onChanged({ (value) in
                            self.globalDragPosition = value.location
                        })
                        .onEnded({ (value) in
                            self.globalDragPosition = CGPoint.zero
                        })
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .global)
                        .updating($isTouched, body: { (_, isTouched, _) in
                            isTouched = true
                        })
                )
            })
            .buttonStyle(BlankButtonStyle(isTapped: $isTapped))
            .accessibilityElement(children: /*@START_MENU_TOKEN@*/.ignore/*@END_MENU_TOKEN@*/)
            .accessibility(label: Text("Open Playground Website"))
            .accessibility(hint: Text("Double-tap to open our website, 'playground dot A I'"))
            .foregroundColor(Color(.label))
        }
    }

struct PGInteractiveLogo_Previews: PreviewProvider {
    static var previews: some View {
        PGInteractiveLogo()
    }
}

let generator = UISelectionFeedbackGenerator()

struct LetterContainer : View {
    
    var up : Bool
    var imageName : String
    @Binding var globalDragPosition : CGPoint
    
    @State var letterFrame : CGRect = .zero
    
    var isHighlighted : Bool {
        get {
            if !UIAccessibility.isReduceMotionEnabled {
                if letterFrame.minX <= globalDragPosition.x && letterFrame.maxX >= globalDragPosition.x {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
    
    var body: some View {
            VStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .offset(y: self.isHighlighted ? (up ? -12 : 12) : 0)
                    .animation(.interactiveSpring())
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(key: FramePreferenceKey.self, value: geometry.frame(in: CoordinateSpace.global))
                        }
                    )
            }
            .onPreferenceChange(FramePreferenceKey.self) { value in
                self.letterFrame = value
            }
            .preference(key: HighlightedPreferenceKey.self, value: isHighlighted)
            .onPreferenceChange(HighlightedPreferenceKey.self) { value in
                generator.selectionChanged()
            }
    }
}

struct HighlightedPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct BlankButtonStyle: ButtonStyle {
    
    @Binding var isTapped : Bool
    var configuration = Self.Configuration
    
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label.preference(key: TappedPreferenceKey.self, value: configuration.isPressed).onPreferenceChange(TappedPreferenceKey.self) { value in
            self.isTapped = value
        }
    }

}

struct TappedPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
