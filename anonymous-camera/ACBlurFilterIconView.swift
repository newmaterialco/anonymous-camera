//
//  ACBlurFilterIconView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ACBlurFilterIconView: View {
    var body: some View {
        Circle()
            .scale(0.75)
            .foregroundColor(.white)
            .blur(radius: 4)
    }
}

struct ACBlurFilterIconView_Previews: PreviewProvider {
    static var previews: some View {
        ACBlurFilterIconView()
    }
}

//struct ACPixelFilterIconView: View {
//    var body: some View {
//        VStack {
//            HStack{
//                Rectangle()
//                    .foregroundColor(Color.white.opacity(0.5))
//            }
//            HStack {
//
//            }
//        }
//    }
//}
//
//struct ACBlurFilterIconView_Previews: PreviewProvider {
//    static var previews: some View {
//        ACBlurFilterIconView()
//    }
//}
