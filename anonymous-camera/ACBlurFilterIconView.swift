//
//  ACBlurFilterIconView.swift
//  anonymous-camera
//
//  Created by Aaron Abentheuer on 20/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI

struct ACBlurFilterIconView: View {
    
    var isSelected : Bool
    
    var body: some View {
        Circle()
            .scale(isSelected ? 0.62 : 0.62)
            .foregroundColor(isSelected ? Color.black : Color.white)
            .blur(radius: isSelected ? 4 : 2)
    }
}

struct ACBlurFilterIconView_Previews: PreviewProvider {
    
    
    static var isSelected = false
    
    static var previews: some View {
        ACBlurFilterIconView(isSelected: isSelected)
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
