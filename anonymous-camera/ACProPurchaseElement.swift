////
////  ACProPurchaseElement.swift
////  anonymous-camera
////
////  Created by Aaron Abentheuer on 06/06/2020.
////  Copyright © 2020 Aaron Abentheuer. All rights reserved.
////
//
//import SwiftUI
//
//struct ACProPurchaseElement: View {
//
//    @EnvironmentObject var sceneInformation : ACScene
//    @EnvironmentObject var anonymisation : ACAnonymisation
//
//    @State var communicatingWithAppStore : Bool = false
//
//    @State private var isAnimating = false
//
//    var foreverAnimation: Animation {
//        Animation.linear(duration: 0.72).repeatForever(autoreverses: false)
//    }
//
//    var body: some View {
//
//        HStack {
//                Button(action: {
//
//                    self.communicatingWithAppStore = true
//
//                    InAppManager.shared.restore { success in
//
//
//                        self.communicatingWithAppStore = false
//
//                        if success {
//                            print("success")
//                            self.sceneInformation.proPurchased = InAppManager.shared.isPro
//
//                            self.anonymisation.includeWatermark = false
//                            self.sceneInformation.interviewModeAvailable = true
//                        }
//                    }
//                }) {
//                    Text("RESTORE")
//                        .font(Font.system(size: 18).uppercaseSmallCaps())
//                        .foregroundColor(Color(UIColor.label))
//                }
//                .transition(AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.75)))
//
//
//            Spacer()
//
//            Button(action: {
//
//                self.communicatingWithAppStore = true
//                self.isAnimating = true
//
//                InAppManager.shared.purchase { success in
//
//                    print("purchase callback")
//
//                    self.communicatingWithAppStore = false
//
//                    if success {
//                        print("success")
//                        self.sceneInformation.proPurchased = InAppManager.shared.isPro
//
//                        self.anonymisation.includeWatermark = false
//                        self.sceneInformation.interviewModeAvailable = true
//                    }
//
//                }
//
//            }) {
//
//
//                HStack {
//                    HStack(spacing: 6) {
//                        Text("BUY")
//                            .font(Font.system(size: 18).uppercaseSmallCaps())
//                            .opacity(0.75)
//                        Text(self.sceneInformation.product?.localizedPrice ?? "")
//                            .font(Font.system(size: 18).uppercaseSmallCaps())
//                    }
//                    .opacity(self.communicatingWithAppStore ? 0 : 1)
//                }
//                .padding(.vertical, 8)
//                .padding(.horizontal, 12)
//                .overlay(
//                    HStack {
//                        Rectangle()
//                            .foregroundColor(Color.clear)
//                        Image("app-store-style-spinner")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .scaleEffect(0.75)
//                        .rotationEffect(
//                                Angle(degrees: isAnimating ? 360 : 0)
//                        )
//                        .animation(foreverAnimation)
//                    }
//                    .opacity(self.communicatingWithAppStore ? 1 : 0)
//                )
//
//                .foregroundColor(self.communicatingWithAppStore ? Color.blue : Color.white)
//                .background(self.communicatingWithAppStore ? Color.clear : Color.blue)
//                .cornerRadius(radius: 100, style: .circular)
//            }
//        }
//    }
//}
