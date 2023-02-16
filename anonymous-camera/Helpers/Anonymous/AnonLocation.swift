//
//  AnonLocation.swift
//  anonymous-camera
//
//  Created by Alisdair Mills on 03/06/2020.
//  Copyright © 2020 Aaron Abentheuer. All rights reserved.
//

import CoreLocation

internal class AnonLocation: NSObject {
    
    internal typealias AuthResponse = (_: AuthStatus) -> Void
    internal typealias LocationUpdate = (_: CLLocation) -> Void
    
    private let locationManager = CLLocationManager()
    private var authHandler: AuthResponse?
    private var locationHandler: LocationUpdate?
    
    internal enum AuthStatus {
        case requiresPrompt
        case inUse
        case always
        case showDenied
    }
    
    private static var instance: AnonLocation?
    internal static var shared: AnonLocation {
        if instance == nil {
            instance = AnonLocation()
            instance?.configure()
        }
        return instance!
    }
    
    internal static func requestAuthPermission(_ block: @escaping AnonLocation.AuthResponse) {
        AnonLocation.shared.authHandler = block
        AnonLocation.shared.locationManager.requestWhenInUseAuthorization()
    }
    
    internal func onUpdate(_ block: LocationUpdate?) {
        locationHandler = block
        if let _ = locationHandler { locationManager.startUpdatingLocation() }
        else { locationManager.stopUpdatingLocation() }
    }
    
    private func configure() {
        locationManager.delegate = self
    }
    
}

extension AnonLocation: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            if status == .denied { self.authHandler?(.showDenied) }
            else if status == .notDetermined { self.authHandler?(.requiresPrompt) }
            else if status == .authorizedAlways { self.authHandler?(.always) }
            else { self.authHandler?(.inUse) }
        }
    }
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async { self.locationHandler?(location) }
        }
    }
}
