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
    @Published var faces : [Anon.AnonFace] = []
    
    @Published var anonymisationType : Anon.AnonDetection = .face {
        didSet {
            self.updateAnonConfiguration()
        }
    }
    
    @Published var exifLocation : Bool = false
    @Published var exifDateTime : Bool = false
    
    @Published var distortAudio : Bool = false
    
    enum ACInterviewModeConfiguration {
        case off
        case effectTrailing
        case effectLeading
    }
    
    @Published var interviewModeConfiguration : ACInterviewModeConfiguration = .off {
        didSet {
            if interviewModeConfiguration == .off {
                interviewModeIsOn = false
                interviewModeEffectsSwitched = false
                anonymous.edge = .right
            } else {                
                
                if let selectedFilter = selectedFilter {
                    if !selectedFilter.modifiesImage {
                        self.select(filter: filters[1])
                    }
                }

                interviewModeIsOn = true
                
                if interviewModeConfiguration == .effectTrailing {
                    interviewModeEffectsSwitched = false
                    anonymous.edge = .right
                } else {
                    interviewModeEffectsSwitched = true
                    anonymous.edge = .left
                }
            }
        }
    }
    
    @Published var interviewModeIsOn : Bool = false {
        
        didSet {
            if !interviewModeIsOn {
                interviewModeDividerXOffset = .zero
            }
        }
    }
    
    @Published var interviewModeEffectsSwitched : Bool = false
    
    @Published var interviewModeDividerXOffset : CGFloat = .zero {
        didSet {
            if interviewModeDividerXOffset == .zero {
                anonymous.point = .zero
            } else {
                anonymous.point = CGPoint(x: 0, y: interviewModeDividerXOffset)
            }
        }
    }
    
    @Published var selectedFilter : ACFilter? {
        didSet {
            #if !targetEnvironment(simulator)
            
            if let f = selectedFilter {
                switch f.filterIdentifier {
                case "AC_FILTER_BLUR":
                    anonymous.showMask(type: .blur, detection: self.anonymisationType)
                case "AC_FILTER_PIXEL":
                    anonymous.showMask(type: .pixelate, detection: self.anonymisationType)
                default:
                    anonymous.showMask(type: .none, detection: self.anonymisationType)
                    self.interviewModeConfiguration = .off
                }
            }
            #endif
        }
    }
    
    private func updateAnonConfiguration () {
        #if !targetEnvironment(simulator)
        
        if let f = selectedFilter {
            switch f.filterIdentifier {
            case "AC_FILTER_BLUR":
                anonymous.showMask(type: .blur, detection: .face)
            case "AC_FILTER_PIXEL":
                anonymous.showMask(type: .pixelate, detection: .face)
            default:
                anonymous.showMask(type: .none, detection: .face)
                self.interviewModeConfiguration = .off
            }
        }
        #endif
    }
    
    init() {
        self.select(filter: filters[1])
        anonymous.showMask(type: .blur, detection: .face)
    }
    
    func switchEffectsInInterviewMode () {
        if interviewModeConfiguration != .off {
            if interviewModeConfiguration == .effectTrailing {
                self.interviewModeConfiguration = .effectLeading
            } else if interviewModeConfiguration == .effectLeading {
                self.interviewModeConfiguration = .effectTrailing
            }
        }
    }
    
    func nextLens () {
        print(anonymous.availableLens.count)
        
        anonymous.showCamera(facing: .back, lens: .telephoto)
    }
    
    @Published var cameraFacingFront : Bool = true
    
    func toggleFrontAndBackCamera () {
        if anonymous.facing == .front {
            self.cameraFacingFront = false
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                anonymous.showCamera(facing: .back)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                anonymous.showCamera(facing: .front)
            }
            self.cameraFacingFront = true
        }
    }
    
    func takePhoto () {
        anonymous.takePhoto(fixedDate: false, location: nil) { _ in
            print("photo")
            return
        }
    }
    
    func startRecording () {
//        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
//            anonymous.startRecord(audio: false, anonVoice: false)
//        }
        print("start recording")
    }
    
    func finishRecording () {
        anonymous.endRecord(fixedDate: true, location: nil) { _ in
            print("end recording")

            return
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
    ACFilter(filterIdentifier: "AC_FILTER_NONE", name: NSLocalizedString("No Filter", comment: "Not any"), icon: UIImage(named: "AC_FILTER_NONE_ICON")!, selected: false, modifiesImage: false),
    ACFilter(filterIdentifier: "AC_FILTER_BLUR", name: NSLocalizedString("Blur", comment: "A smear or stain that obscures"), icon: UIImage(named: "AC_FILTER_BLUR_ICON")!, selected: false, modifiesImage: true),
    ACFilter(filterIdentifier: "AC_FILTER_PIXEL", name: NSLocalizedString("Pixelate", comment: "Any of the small discrete elements that together constitute an image (as on a television or digital screen)"), icon: UIImage(named: "AC_FILTER_PIXEL_ICON")!, selected: false, modifiesImage: true)
]
