//
//  ACSettingsStore.swift
//  SwitcherTest
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI
import Combine

class ACAnonymisation : ObservableObject {
    
    static var shared = ACAnonymisation()
    
    @Published var filters : [ACFilter] = availableFilters
    @Published var faceRectangles : [Anon.AnonFace] = []
    
    var selectedFilter : ACFilter? {
        didSet {
            #if !targetEnvironment(simulator)
            if let f = selectedFilter {
                switch f.filterIdentifier {
                case "AC_FILTER_BLUR":
                    anonymous.showMask(type: .blur, detection: .face)
                case "AC_FILTER_PIXEL":
                    anonymous.showMask(type: .pixelate, detection: .face)
                default:
                    anonymous.showMask(type: .none, detection: .face)
                }
            }
            #endif
        }
    }
        
    func select(filter : ACFilter) {
        for (index, f) in filters.enumerated() {
            if filter.id == f.id {
                filters[index].selected = true
                self.selectedFilter = f
            } else {
                filters[index].selected = false
            }
        }
    }
    
    func didSwitch(from: Anon.AnonState, to: Anon.AnonState) {
        print("did switch")
    }
}

struct ACFilter : Identifiable {
    var id = UUID()
    var filterIdentifier : String
    var name : String
    var icon : UIImage
    var selected : Bool
    var modifiesImage : Bool
}

var availableFilters = [
    ACFilter(filterIdentifier: "AC_FILTER_NONE", name: NSLocalizedString("No Filter", comment: "Not any"), icon: UIImage(named: "AC_FILTER_NONE_ICON")!, selected: true, modifiesImage: false),
    ACFilter(filterIdentifier: "AC_FILTER_BLUR", name: NSLocalizedString("Blur", comment: "A smear or stain that obscures"), icon: UIImage(named: "AC_FILTER_BLUR_ICON")!, selected: false, modifiesImage: true),
    ACFilter(filterIdentifier: "AC_FILTER_PIXEL", name: NSLocalizedString("Pixelate", comment: "Any of the small discrete elements that together constitute an image (as on a television or digital screen)"), icon: UIImage(named: "AC_FILTER_PIXEL_ICON")!, selected: false, modifiesImage: true)
]
