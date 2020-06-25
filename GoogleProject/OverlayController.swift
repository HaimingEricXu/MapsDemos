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
    
    private var overlays = [GMSCircle]()

    // Heatmap buffering
    private var activityView = UIActivityIndicatorView(style: .whiteLarge)
    
    init() {
        
    }
    
    func clear() {
        for x in overlays {
            x.map = nil
        }
    }
    
    func showActivityIndicatory(view: UIView) {
        activityView.center = view.center
        activityView.style = UIActivityIndicatorView.Style.large
        activityView.color = .black
        view.addSubview(activityView)
        view.bringSubviewToFront(activityView)
        activityView.startAnimating()
    }
    
    func hideActivityIndicatory() {
        activityView.removeFromSuperview()
    }
    
    func drawCircle(mapView: GMSMapView, darkModeToggle: Bool, lat: Double, long: Double) {
        let circle = GMSCircle()
        circle.map = nil
        circle.position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        circle.radius = 2000
        circle.fillColor = .clear
        circle.strokeColor = .black
        circle.strokeWidth = 3.4
        circle.map = mapView
        overlays.append(circle)
    }
    
    // Draws a pre-set rectangle in specified area; can/will change this to be more flexible and appear in more places
    func drawRect(mapView: GMSMapView, darkModeToggle: Bool) {
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
