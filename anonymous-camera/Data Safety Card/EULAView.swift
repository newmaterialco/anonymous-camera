//
//  EULAView.swift
//  SafetyCard
//
//  Created by Sarah Mautsch on 31.03.20.
//  Copyright © 2020 Sarah Mautsch. All rights reserved.
//

import SwiftUI

struct EULAView: View {
    @Binding var isPresented : Bool
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading){
                VStack(alignment: .leading){
                    HStack {
                        Spacer()
                        Image(systemName: "xmark.circle")
                        .font(Font.system(size: 24, weight: .semibold))
                        .foregroundColor(Color("lightblue").opacity(0.6))
                        .onTapGesture {
                            self.isPresented.toggle()
                        }
                        .padding(.trailing, 8)
                        .padding(.top, 32)
                    }
        
            
                    HStack (alignment: .center) {
                        HStack (spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(Font.system(size: 30, weight: .semibold))
                            Text("Terms of Use")
                                .font(Font.system(size: 32, weight: .semibold))
                        }
                    }
                    Text("Last Updated 31st of March 2020")
                    .font(Font.system(size: 14, weight: .medium))
                    .foregroundColor(Color("lightblue"))
                }.padding(.bottom, 40)
                
            Group{
                HeadlineText(text: "Acceptance of terms of use")
                MainText(text: "The following terms and conditions, together with any other notices or documents that they expressly incorporate by reference (collectively, these “Terms of Use”), are entered into by and between You and playground.ai, a [STATE] corporation (“Playground”, “we” or “us”). The Terms of Use govern your access to and use of the Playground mobile application (“App”) and the Playground websites (collectively, “Website”) (the App and the Website, are collectively referred to hereinafter as the “Platform”), including any content, functionality and services offered on or through the Platform, whether as a guest or a registered user.")
                MainTextHighlight(text: "Important: Please review the mutual agreement set forth below carefully, as it will requite you to resolve disputes with Playground on an individual basis (waiving your right to a class action) through final and binding arbitration. By entering this egreement, you expressly acknowledge that you have read and understand all of the terms of this mutual arbitration agreement and have taken the time to consider the consequences of this important decision. \n\nThese terms of use also contain releases, limitations on liability, and provisions on indemnity and assumption of risk, all of which may limit your legal rights and remedies. Please review them carefully.".uppercased())
                MainText(text: "Please read the Terms of Use carefully before you start to use the App. By using the App or by clicking to accept or agree to the Terms of Use when this option is made available to you, you also accept and agree to be bound and abide by the Additional Terms (as explained below), which are incorporated herein by reference. If you do not want to agree to these Terms of Use or Additional Terms, you must not access or use the Platform.")
            }
//                Group{
//
//                }
//                Group{
//
//                }
//                
          }.padding(.horizontal, 32)
        }
    }
}


struct EULAView_Previews: PreviewProvider {
    static var previews: some View {
        EULAView(isPresented: .constant(false))
    }
}

struct MainTextHighlight: View {
    var text: String
    
    var body: some View {
        VStack{
            Text(text)
                .font(Font.system(size: 16, weight: .semibold, design: .rounded))
                .lineSpacing(6)
                .foregroundColor(Color("text"))
                .padding(.vertical, 16)
        }
    }
}

