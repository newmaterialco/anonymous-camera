//
//  ACPlaygroundCredit.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 02/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ACPlaygroundCredit: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://www.playground.ai") {
               UIApplication.shared.open(url)
           }
        }) {
            VStack{
                Image("playground")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 28)
            }
            .foregroundColor(Color(UIColor.label))
            .opacity(0.5)
        }
    }
}
