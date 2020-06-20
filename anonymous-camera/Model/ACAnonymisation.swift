//
//  ACSettingsStore.swift
//  SwitcherTest
//
//  Created by Aaron Abentheuer on 17/03/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import SwiftUI
import Combine
import SwiftyUserDefaults

extension DefaultsKeys {
    var exifLocation: DefaultsKey<Bool?> { .init("exifLocation", defaultValue: false) }
    var exifDateTime: DefaultsKey<Bool?> { .init("exifDateTime", defaultValue: true) } 
    var distortAudio: DefaultsKey<Bool?> { .init("distortAudio", defaultValue: false) }
    var includeWatermark: DefaultsKey<Bool?> { .init("includeWatermark", defaultValue: true) }
    var cameraFacingFront: DefaultsKey<Bool?> { .init("cameraFacingFront", defaultValue: true) }
    var interviewMode: DefaultsKey<Bool?> { .init("interviewMode", defaultValue: false) }
}

class ACAnonymisation : ObservableObject {
    
    static var shared = ACAnonymisation()
    
    @Published var filterGroups : [ACFilterGroup] = availableFilterGroups
    @Published var filterTypes : [ACFilterType] = availableFilterTypes
    @Published var allAvailableFilters : [ACFilter] = allFilters
    @Published var faces : [Anon.AnonFace] = []
    @Published var selectedFilter : ACFilter?
    
    @Published var anonymisationType : Anon.AnonDetection = .face {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.36) {
                self.updateAnonConfiguration()
            }
        }
    }
    
    @Published var exifLocation : Bool = Defaults[\.exifLocation]! {
        didSet {
            
            Defaults[\.exifLocation]! = exifLocation
            
            if exifLocation {
                ACScene.shared.hudString = "Include Location"
                Anon.requestLocationAccess { status in
                    if status == .granted { anonymous.getLocation(true) }
                    else { anonymous.getLocation(false) }
                }
            } else {
                ACScene.shared.hudString = "Remove Location"
                anonymous.getLocation(false)
            }
            
            ACScene.shared.hudLoading = false
            ACScene.shared.hudTint = UIColor.black
            ACScene.shared.hudIcon = nil
            
            ACScene.shared.showHUD = true
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                ACScene.shared.showHUD = false
            }
        }
    }
    
    
    
    @Published var exifDateTime : Bool = Defaults[\.exifDateTime]! {
        didSet {
            
            Defaults[\.exifDateTime]! = exifDateTime
            
            if exifDateTime {
                ACScene.shared.hudString = "Include Timestamp"
            } else {
                ACScene.shared.hudString = "Remove Timestamp"
            }
            
            ACScene.shared.hudLoading = false
            ACScene.shared.hudTint = UIColor.black
            ACScene.shared.hudIcon = nil
            
            ACScene.shared.showHUD = true
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                ACScene.shared.showHUD = false
            }
        }
    }

    @Published var distortAudio : Bool = Defaults[\.distortAudio]! {
        didSet {
            Defaults[\.distortAudio]! = distortAudio

        }
    }
    
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
                    if !selectedFilter.filterType.modifiesImage {
                        self.select(filterGroup: filterGroups[1])
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
        
    @Published var includeWatermark : Bool = Defaults[\.includeWatermark]! {
        didSet {
            Defaults[\.includeWatermark]! = includeWatermark
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
    
    @Published var timeCode : String = "00:00"
        
    @Published var selectedFilterGroup : ACFilterGroup = availableFilterGroups[1] {
        didSet {
            self.selectedFilter = selectedFilterGroup.filters[selectedFilterGroup.selectedFilterIndex]
            self.updateAnonConfiguration()
        }
    }
    
    private func updateAnonConfiguration () {
        #if !targetEnvironment(simulator)
        
        if let f = selectedFilter {
            
            print(f.filterIdentifier)
            
            switch f.filterIdentifier {
            case "AC_FILTER_COLOUR_WHITE":
                anonymous.fillColor = whiteFilter.colour
                anonymous.pixellateType = .normal
                anonymous.showMask(type: .pixelate, detection: self.anonymisationType)
            case "AC_FILTER_COLOUR_BLACK":
                anonymous.fillColor = blackFilter.colour
                anonymous.pixellateType = .normal
                anonymous.showMask(type: .pixelate, detection: self.anonymisationType)
            case "AC_FILTER_COLOUR_YELLOW":
                anonymous.fillColor = yellowFilter.colour
                anonymous.pixellateType = .normal
                anonymous.showMask(type: .pixelate, detection: self.anonymisationType)
            case "AC_FILTER_NOISE":
                anonymous.fillColor = nil
                anonymous.pixellateType = .bwNoise
                anonymous.showMask(type: .pixelate, detection: self.anonymisationType)
            case "AC_FILTER_BLUR":
                anonymous.showMask(type: .blur, detection: self.anonymisationType)
            case "AC_FILTER_PIXEL":
                anonymous.fillColor = nil
                anonymous.pixellateType = .normal
                anonymous.showMask(type: .pixelate, detection: self.anonymisationType)
            default:
                anonymous.showMask(type: .none, detection: self.anonymisationType)
                self.interviewModeConfiguration = .off
            }
        }
        #endif
    }
    
    init() {
        self.select(filterGroup: filterGroups[1])
        anonymous.padding = 0.05
        anonymous.blurRadius = 60
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
//
//    func nextLens () {
//        print(anonymous.availableLens.count)
//
//        anonymous.showCamera(facing: .back, lens: .telephoto)
//    }
    
    @Published var cameraFacingFront : Bool = Defaults[\.cameraFacingFront]! {
        didSet {
            Defaults[\.cameraFacingFront]! = cameraFacingFront
        }
    }
    
    func toggleFrontAndBackCamera () {
        if anonymous.facing == .front {
            self.cameraFacingFront = false
            DispatchQueue.main.asyncAfter(deadline: .now()+0.35) {
                anonymous.showCamera(facing: .back)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.35) {
                anonymous.showCamera(facing: .front)
            }
            self.cameraFacingFront = true
        }
    }
    
    let impactGenerator = UIImpactFeedbackGenerator()
    
    func takePhoto () {
        
        if self.includeWatermark {
            anonymous.watermark = UIImage(named: "AC_WATERMARK")
        } else {
            anonymous.watermark = nil
        }
        
        impactGenerator.impactOccurred(intensity: 0.5)
        
        anonymous.takePhoto(fixedDate: !self.exifDateTime, location: nil) { success in
            
            print("took photo")
            
            if success {
                
            }
            ACScene.shared.hudString = "Saved"
            ACScene.shared.showHUD = true
            ACScene.shared.hudTint = UIColor.systemGreen
            ACScene.shared.hudIcon = UIImage(systemName: "checkmark.circle.fill")
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                ACScene.shared.showHUD = false
            }
            
            return
        }
    }
    
    var startDate : Date? = nil
    var timeCodeTimer : Timer? = nil
    
    func startRecording () {
        
        if self.includeWatermark {
            anonymous.watermark = UIImage(named: "AC_WATERMARK")
        } else {
            anonymous.watermark = nil
        }
        
        anonymous.startRecord(audio: true, anonVoice: self.distortAudio)
        
        if let t = timeCodeTimer {
            t.invalidate()
            timeCodeTimer = nil
        }
        
        timeCode = "00:00"
        startDate = Date()
        
        timeCodeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            
            let difference = Date().timeIntervalSince(self.startDate!)
            
            if let f = difference.format() {
                self.timeCode = f
            }
        })
        
        print("start recording")
    }
    
    func finishRecording () {
        print("starting to finish")
        
        timeCodeTimer?.invalidate()
        
        ACScene.shared.hudString = "Saving Video"
        ACScene.shared.hudLoading = true
        ACScene.shared.hudTint = UIColor.black
        ACScene.shared.hudIcon = nil
        
        ACScene.shared.showHUD = true

        
        anonymous.endRecord(fixedDate: false, location: nil) { completion in
            
            ACScene.shared.hudString = "Saved"
            ACScene.shared.showHUD = true
            ACScene.shared.hudLoading = false
            ACScene.shared.hudTint = UIColor.systemGreen
            ACScene.shared.hudIcon = UIImage(systemName: "checkmark.circle.fill")
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                ACScene.shared.showHUD = false
            }
            
        }
    }
        
    func select(filterGroup : ACFilterGroup) {
        for (index, f) in filterGroups.enumerated() {
            if filterGroup.id == f.id {
                filterGroups[index].selected = true
                self.selectedFilterGroup = f
            } else {
                filterGroups[index].selected = false
            }
        }
    }
    
    func select(filter : ACFilter, inGroup group: ACFilterGroup) {
        
        for (index, g) in filterGroups.enumerated() {
            if group.id == g.id {
                
                self.select(filterGroup: g)
                
                for (jndex, f) in group.filters.enumerated() {
                    if filter.id == f.id {
                        filterGroups[index].filters[jndex].selected = true
                        filterGroups[index].selectedFilterIndex = jndex
                        
                        self.selectedFilter = filter
                        
                        print("selected a filter")
                    } else {
                        filterGroups[index].filters[jndex].selected = false
                    }
                }
            }
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.36) {
            self.updateAnonConfiguration()
        }
    }
    
    func didSwitch(from: Anon.AnonState, to: Anon.AnonState) {
    }
}

struct ACFilterGroup : Identifiable {
    var id = UUID()
    var groupIdentifier : String
    var name : String
    var selected : Bool
    var selectedFilterIndex : Int
    var modifiesImage : Bool
    var filters : [ACFilter]
    var availableFilterTypes : [ACFilterType]
}

struct ACFilter : Identifiable {
    var id = UUID()
    var filterIdentifier : String
    var name : String
    var selected : Bool
    var colour : UIColor?
    var filterType : ACFilterType
}

struct ACFilterType : Identifiable {
    var id = UUID()
    var filterIdentifier : String
    var icon : UIImage
    var modifiesImage : Bool
}

var noFilterType = ACFilterType(filterIdentifier: "NO_TYPE", icon: UIImage(named: "AC_FILTER_NONE_ICON")!, modifiesImage: false)
var colourFilterType = ACFilterType(filterIdentifier: "COLOUR_TYPE", icon: UIImage(named: "AC_FILTER_COLOUR_ICON")!, modifiesImage: true)
var noiseFilterType = ACFilterType(filterIdentifier: "NOISE_TYPE", icon: UIImage(named: "AC_FILTER_NOISE_ICON")!, modifiesImage: true)
var blurFilterType = ACFilterType(filterIdentifier: "BLUR_TYPE", icon: UIImage(named: "AC_FILTER_BLUR_ICON")!, modifiesImage: true)
//var pixelateFilterType = ACFilterType(filterIdentifier: "PIXEL_TYPE", icon: UIImage(named: "AC_FILTER_PIXEL_ICON")!, modifiesImage: true)


var noFilter = ACFilter(filterIdentifier: "AC_FILTER_NONE", name: NSLocalizedString("No Filter", comment: "Not any"), selected: false, filterType: noFilterType)
var whiteFilter = ACFilter(filterIdentifier: "AC_FILTER_COLOUR_WHITE", name: "White", selected: false, colour: UIColor(red: 1, green: 1, blue: 1, alpha: 1), filterType: colourFilterType)
var blackFilter = ACFilter(filterIdentifier: "AC_FILTER_COLOUR_BLACK", name: "Black", selected: false, colour: UIColor(red: 0, green: 0, blue: 0, alpha: 1), filterType: colourFilterType)

var yellowFilter = ACFilter(filterIdentifier: "AC_FILTER_COLOUR_YELLOW", name: "Yellow", selected: true, colour: UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 1.00), filterType: colourFilterType)

var noiseFilter =  ACFilter(filterIdentifier: "AC_FILTER_NOISE", name: "Noise", selected: false, colour:  nil, filterType: noiseFilterType)

//var pixelateFilter = ACFilter(filterIdentifier: "AC_FILTER_PIXEL", name: NSLocalizedString("Pixelate", comment: "Any of the small discrete elements that together constitute an image (as on a television or digital screen)"), selected: false, filterType: pixelateFilterType)

var blurFilter = ACFilter(filterIdentifier: "AC_FILTER_BLUR", name: NSLocalizedString("Blur", comment: "A smear or stain that obscures"), selected: false, filterType: blurFilterType)

var allFilters = [noFilter, whiteFilter, blackFilter, yellowFilter, noiseFilter, blurFilter]
var availableFilterTypes = [noFilterType, colourFilterType, noiseFilterType, blurFilterType]

var availableFilterGroups = [
    ACFilterGroup(groupIdentifier: "AC_FILTERGROUP_NONE", name: "No Filter", selected: false, selectedFilterIndex: 0, modifiesImage: false, filters: [
        noFilter
    ], availableFilterTypes: [noFilterType]),
    ACFilterGroup(id:UUID(), groupIdentifier: "AC_FILTERGROUP_COVER", name: "Solid", selected: true, selectedFilterIndex: 0, modifiesImage: true, filters: [
        yellowFilter, whiteFilter, blackFilter, noiseFilter
    ], availableFilterTypes: [colourFilterType, noiseFilterType]),
    ACFilterGroup(groupIdentifier: "AC_FILTERGROUP_FILTER", name: "Blur", selected: false, selectedFilterIndex: 0, modifiesImage: true, filters: [
        blurFilter
    ], availableFilterTypes: [blurFilterType])
]

extension TimeInterval {

  func format() -> String? {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = .pad
    
    return formatter.string(from: self)
  }
}
