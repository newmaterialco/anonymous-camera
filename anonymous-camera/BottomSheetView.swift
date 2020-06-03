//
//  BottomSheetView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 30/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

fileprivate enum Constants {
    static let radius: CGFloat = 16
    static let indicatorHeight: CGFloat = 6
    static let indicatorWidth: CGFloat = 60
    static let snapRatio: CGFloat = 0.25
    static let minHeightRatio: CGFloat = 0.3
}

struct BottomSheetView<Content: View>: View {
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content
    
    @GestureState private var translation: CGFloat = 0
    @GestureState private var observedTranslation: CGFloat = 0
    
    let selectionGenerator = UISelectionFeedbackGenerator()
    let impactGenerator = UIImpactFeedbackGenerator()
    
    private var offset: CGFloat {
        sceneInformation.bottomSheetIsOpen ? 0 : maxHeight - minHeight
    }
    
    private var indicator: some View {
        HStack (spacing: sceneInformation.isDraggingBottomSheet ? -4 : sceneInformation.bottomSheetIsOpen ? -3 : -3) {
            RoundedRectangle(cornerRadius: Constants.radius)
                .fill(Color.gray)
                .frame(
                    width: 24,
                    height: 4
            )
                .rotationEffect(Angle(degrees: sceneInformation.isDraggingBottomSheet ? 0 : sceneInformation.bottomSheetIsOpen ? 16 : -16), anchor: UnitPoint(x: 1, y: 0.5))
            RoundedRectangle(cornerRadius: Constants.radius)
                .fill(Color.gray)
                .frame(
                    width: 24,
                    height: 4
            )
                .rotationEffect(Angle(degrees: sceneInformation.isDraggingBottomSheet ? 0 : sceneInformation.bottomSheetIsOpen ? -16 : 16), anchor: UnitPoint(x: 0, y: 0.5))
            
        }
        .offset(x: 0, y: sceneInformation.isDraggingBottomSheet ? 0 : sceneInformation.bottomSheetIsOpen ? 4 : -4)
        .onTapGesture {
            withAnimation(Animation.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                self.sceneInformation.bottomSheetIsOpen.toggle()
                if self.sceneInformation.bottomSheetIsOpen {
                    self.dragOffsetPercentage = 0
                }
                self.selectionGenerator.selectionChanged()
            }
        }
    }
    
    init(maxHeight: CGFloat, minHeight : CGFloat, @ViewBuilder content: () -> Content) {
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.content = content()
    }
    
    @State var movingViewFrame : CGRect = .zero
    @State var fixedViewFrame: CGRect = .zero
    
    @State var showSafetyCard : Bool = false
    
    @State var dragOffsetPercentage : CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack {
                    self.indicator.padding(EdgeInsets(top: 16, leading: 0, bottom: 12, trailing: 0))
                    HStack{
                        Spacer()
                        ACFilterSelector()
                        Spacer()
                    }
                    
                    RoundedRectangle(cornerRadius: 1)
                        .foregroundColor(
                            Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.label.withAlphaComponent(0.25) : UIColor.white.withAlphaComponent(0.25))
                    )
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                        .padding(.horizontal)
                        .padding(.top)
                        .opacity((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? 1 : 0)
                        .offset(y: (self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? 0 : 24)
                }
                .background(
                    Color.black.opacity(0.00001)
                )
                .simultaneousGesture(
                    DragGesture(coordinateSpace: .global).updating(self.$translation) { value, state, _ in
                        if self.fixedViewFrame.contains(value.location) {
                        } else {
                            if self.sceneInformation.isDraggingBottomSheet {
                                state = value.translation.height
                            }
                        }
                    }
                    .onChanged({ value in
                        
                        if value.translation.height.abs > value.translation.width.abs {
                            if !self.sceneInformation.bottomSheetIsOpen {
                                if value.translation.height < 0 {
                                    self.sceneInformation.isDraggingBottomSheet = true
                                }
                            } else {
                                self.sceneInformation.isDraggingBottomSheet = true
                            }
                        }
                        
                    })
                        .onEnded { value in
                            if self.sceneInformation.isDraggingBottomSheet {
                                self.sceneInformation.isDraggingBottomSheet = false
                                let snapDistance = self.maxHeight * Constants.snapRatio
                                guard abs(value.translation.height) > snapDistance else {
                                    return
                                }
                                self.sceneInformation.bottomSheetIsOpen = value.translation.height < 0
                                if self.sceneInformation.bottomSheetIsOpen {
                                    self.dragOffsetPercentage = 0
                                }
                            }
                    }
                )
                
                UIScrollViewWrapper(content: {
                    VStack {
                        ChildFrameReader(frame: self.$movingViewFrame, content: {
                            Spacer()
                        })
                        
                        
                        Picker(selection: self.$anonymisation.anonymisationType, label: Text("What is your favorite color?")) {
                            Text("Face").tag(Anon.AnonDetection.face)
                            Text("Full Body").tag(Anon.AnonDetection.body)
                        }.pickerStyle(SegmentedPickerStyle())
                        
                        VStack {
                            ForEach(self.anonymisation.filterGroups.indices) { idx in
                                VStack {
                                    ForEach(self.anonymisation.filterGroups[idx].filters.indices) { jdx in
                                        HStack {
                                            Text(self.anonymisation.filterGroups[idx].filters[jdx].name)
                                            Spacer()
                                            Image(uiImage: UIImage(systemName: "checkmark")!)
                                                .opacity((self.anonymisation.filterGroups[idx].selectedFilterIndex == jdx) ? 1 : 0)
                                        }
                                        .padding()
                                        .onTapGesture {
                                            print("tapped")
                                            self.anonymisation.select(filter: self.anonymisation.filterGroups[idx].filters[jdx], inGroup: self.anonymisation.filterGroups[idx])
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack {
                            
                            HStack {
                                Text("Include Location")
                                Spacer()
                                Toggle(isOn: self.$anonymisation.exifLocation) {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            
                            HStack {
                                Text("Include Date+Time")
                                Spacer()
                                Toggle(isOn: self.$anonymisation.exifDateTime) {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            
                            HStack {
                                Text("Distort Audio")
                                Spacer()
                                Toggle(isOn: self.$anonymisation.distortAudio) {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            
                            HStack {
                                Text("Split Screen")
                                Spacer()
                                Toggle(isOn: self.$anonymisation.splitScreenAvailable) {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            
                            HStack {
                                Text("Watermark")
                                Spacer()
                                Toggle(isOn: self.$anonymisation.includeWatermark) {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(radius: 12, style: .continuous)
                        
                        Button(action: {
                            self.showSafetyCard.toggle()
                        }) {
                            DocumentButton(title: "Safety & Privacy", icon: "checkmark.shield.fill", readingtime: "")
                                .frame(maxWidth: .infinity)
                        }
                        .sheet(isPresented: self.$showSafetyCard) {
                            SafetyCard(isPresented: self.$showSafetyCard)
                        }
                        
                        ACPlaygroundCredit()
                        
                    }
                    .padding(.horizontal)
                    .frame(width: geometry.size.width,
                               height: nil,
                               alignment: .topLeading)
                    .background(Color.clear)
                }, bottomSheetIsOpen: self.$sceneInformation.bottomSheetIsOpen, dragOffsetPercentage: self.$dragOffsetPercentage)
                .background(Color.clear)
                .opacity((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? 1 : 0)
                .offset(y: (self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? 0 : 48)
                .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
            .background(
                Rectangle()
                    .foregroundColor(.clear)
                    .background(
                        ZStack {
                            Blur(style: .systemChromeMaterial)
                                .opacity((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? 1 : 0)
                            Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.systemBackground.withAlphaComponent(0.75) : UIColor.black.withAlphaComponent(0))
                        }
                        .clipShape(
                            RoundedCorner(radius: 12, corners: [.topRight, .topLeft])
                        )
                )
                    .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 0)
                    .offset(x: 0, y: (self.sceneInformation.isDraggingBottomSheet || self.sceneInformation.bottomSheetIsOpen) ? 0 : self.minHeight)
            )
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: max(self.offset + self.translation, 0))
            .offset(y: self.sceneInformation.bottomSheetIsOpen ? 48*self.dragOffsetPercentage : 0)
            .animation(self.sceneInformation.isDraggingBottomSheet ? Animation.interactiveSpring(response: 0.02, dampingFraction: 0.9, blendDuration: 0.25) : Animation.interactiveSpring(response: 0.32, dampingFraction: 0.8, blendDuration: 0.25), value: self.translation)
            .animation(Animation.interactiveSpring(response: 0.3, dampingFraction: 0.9, blendDuration: 0.25), value: self.sceneInformation.bottomSheetIsOpen)
            .animation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.7, blendDuration: 0.25))
            .animation(nil, value: self.dragOffsetPercentage)
        }
    }
}

struct ChildFrameReader<Content: View>: View {
    @Binding var frame: CGRect
    let content: () -> Content
    var body: some View {
        ZStack {
            content()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .global))
                    }
            )
        }
        .onPreferenceChange(FramePreferenceKey.self) { preferences in
            self.frame = preferences
        }
    }
}


struct ChildPositionReader<Content: View>: View {
    @Binding var position: CGPoint
    let content: () -> Content
    var body: some View {
        ZStack {
            content()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: PositionPreferenceKey.self, value: CGPoint(x: proxy.frame(in: .global).minX, y: proxy.frame(in: .global).minY))
                    }
            )
        }
        .onPreferenceChange(PositionPreferenceKey.self) { preferences in
            self.position = preferences
        }
    }
}

struct FramePreferenceKey: PreferenceKey {
    typealias Value = CGRect
    static var defaultValue: Value = .zero
    
    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

struct PositionPreferenceKey: PreferenceKey {
    typealias Value = CGPoint
    static var defaultValue: Value = .zero
    
    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetView(maxHeight: 600, minHeight: 12) {
            Rectangle().fill(Color.red)
        }.edgesIgnoringSafeArea(.all)
    }
}


struct ACFilterSelector: View {
    
    @EnvironmentObject var anonymisation : ACAnonymisation
    @EnvironmentObject var sceneInformation : ACScene
    
    let generator = UISelectionFeedbackGenerator()
    
    var body: some View {
        ZStack {
            HStack(spacing: sceneInformation.deviceOrientation.isLandscape ? 18 : 12){
                ForEach(anonymisation.filterGroups.indices) { idx in
                    ACFilterButton(filterGroup: self.$anonymisation.filterGroups[idx])
                }
            }
        }
    }
}

struct ACFilterButton: View {
    
    @EnvironmentObject var sceneInformation : ACScene
    @EnvironmentObject var anonymisation : ACAnonymisation
    @State internal var isBeingTouched : Bool = false
    @Binding var filterGroup : ACFilterGroup
    
    let selectionGenerator = UISelectionFeedbackGenerator()
    let impactGenerator = UIImpactFeedbackGenerator()

    
    var body: some View {
        HStack (alignment: .center) {
            
            Image(uiImage: filterGroup.filters[filterGroup.selectedFilterIndex].filterType.icon)
                .foregroundColor(
                    filterGroup.selected ? (filterGroup.filters[filterGroup.selectedFilterIndex].filterType.modifiesImage ? Color(.black) :
                        Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.systemBackground : UIColor.black)
                        ) :
                        Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.label : UIColor.white)
            )
                .rotationEffect(sceneInformation.deviceRotationAngle)
                .animation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.6, blendDuration: 0), value: sceneInformation.deviceRotationAngle)
            
            if (filterGroup.selected && !sceneInformation.deviceOrientation.isLandscape) {
                Text(filterGroup.filters[filterGroup.selectedFilterIndex].name)
                    .font(Font.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(
                        filterGroup.selected ? (filterGroup.filters[filterGroup.selectedFilterIndex].filterType.modifiesImage ? Color(.black) :
                            Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.systemBackground : UIColor.black)
                            
                            ) : Color(.label)
                )
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .transition(AnyTransition.scale(scale: 0.5, anchor: UnitPoint(x: 0, y: 0.5)).combined(with: AnyTransition.opacity))
                    .animation(Animation.easeInOut)
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
                
                filterGroup.selected ? (
                    filterGroup.filters[filterGroup.selectedFilterIndex].filterType.modifiesImage ? Color("highlight") :
                        
                        Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.label : UIColor.white)
                    
                    ) : ((isBeingTouched && !self.sceneInformation.isDraggingBottomSheet) ?
                        Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.label.withAlphaComponent(0.75) : UIColor.white.withAlphaComponent(0.75))
                        
                        :
                        
                        Color((self.sceneInformation.bottomSheetIsOpen || self.sceneInformation.isDraggingBottomSheet) ? UIColor.label.withAlphaComponent(0.25) : UIColor.white.withAlphaComponent(0.25))
                )
        )
            .animation(Animation.easeInOut(duration: 0.2), value: self.sceneInformation.isDraggingBottomSheet)
            .clipShape(RoundedRectangle(cornerRadius: 100, style: .circular))
            .scaleEffect(isBeingTouched ? 0.92 : 1)
            .scaleEffect(sceneInformation.deviceOrientation.isLandscape ? (filterGroup.filters[filterGroup.selectedFilterIndex].selected ? 1.12 : 1) : 1)
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
        .simultaneousGesture(
                TapGesture()
                    .onEnded({ _ in
                        self.selectionGenerator.selectionChanged()
                        
                        withAnimation(Animation.interactiveSpring(response: 0.32, dampingFraction: 0.86, blendDuration: 0)) {
                            self.anonymisation.select(filterGroup: self.filterGroup)
                        }
                    })
        )
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
