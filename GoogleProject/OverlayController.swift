//
//  OverlayController.swift
//  GoogleProject
//
//  Created by Haiming Xu on 6/23/20.
//  Copyright © 2020 Haiming Xu. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

class OverlayController {
    
    init() {
        
    }
    
    // Draws a pre-set rectangle in specified area; can/will change this to be more flexible and appear in more places
    func drawPolygon(mapView: GMSMapView, darkModeToggle: Bool) {
        let rect = GMSMutablePath()
        rect.add(CLLocationCoordinate2D(latitude: 37.36, longitude: -122.0))
        rect.add(CLLocationCoordinate2D(latitude: 37.45, longitude: -122.0))
        rect.add(CLLocationCoordinate2D(latitude: 37.45, longitude: -122.2))
        rect.add(CLLocationCoordinate2D(latitude: 37.36, longitude: -122.2))
        let polygon = GMSPolygon(path: rect)
        polygon.fillColor = UIColor(red: 0.25, green: 0, blue: 0, alpha: 0.05);
        polygon.strokeColor = darkModeToggle ? .white : .black
        polygon.strokeWidth = 2
        polygon.map = mapView
    }
}
