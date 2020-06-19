/* Copyright (c) 2020 Google Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit
import GoogleMaps
import GooglePlaces
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialActionSheet

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    private var trafficToggle: Bool = false
    private var darkModeToggle: Bool = false
    private var indoorToggle: Bool = false
    private var zoom: Float = 10.0
    private var currentLat: Double = -33.86
    private var currentLong: Double = 151.20
    private var resultsViewController: GMSAutocompleteResultsViewController?
    private var searchController: UISearchController?
    private var resultView: UITextView?
    private let locationManager = CLLocationManager()
    private var camera: GMSCameraPosition!
    private var mapView: GMSMapView!
    private var marker: GMSMarker!
    @IBOutlet weak private var scene: UIView!
    @IBOutlet weak private var welcomeLabel: UILabel!
    
    private let actionSheet = MDCActionSheetController(title: "Options", message: "Pick a feature")
    private let optionsButton = MDCFloatingButton()
    private let zoomInButton = MDCFloatingButton()
    private let zoomOutButton = MDCFloatingButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorization()
        refreshMap(newLoc: true)
        refreshButtons()
        refreshScreen()
        let traffic = MDCActionSheetAction(title: "Toggle Traffic Overlay",
                                           image: UIImage(systemName: "Home"),
                                           handler: {Void in
                                            self.trafficToggle = !self.trafficToggle
                                            self.refreshMap(newLoc: false)
                                            self.refreshScreen()
                                            })
        let indoor = MDCActionSheetAction(title: "Toggle Indoor Map",
                                          image: UIImage(systemName: "Home"),
                                          handler: {Void in
                                            self.indoorToggle = !self.indoorToggle
                                            self.currentLat = -33.856689
                                            self.currentLong = 151.21526
                                            self.zoom = 20.0
                                            self.refreshMap(newLoc: true)
                                            self.refreshScreen()
                                        })
        let darkMode = MDCActionSheetAction(title: "Toggle Dark Mode",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.darkModeToggle = !self.darkModeToggle
                                                self.refreshMap(newLoc: false)
                                                self.refreshScreen()
                                                self.refreshButtons()
                                        })
        actionSheet.addAction(traffic)
        actionSheet.addAction(indoor)
        actionSheet.addAction(darkMode)
    }
    
    private func refreshScreen() {
        self.view.backgroundColor = darkModeToggle ? .darkGray : .white
        self.scene.backgroundColor = darkModeToggle ? .darkGray : .white
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        searchController?.searchBar.sizeToFit()
        definesPresentationContext = true
        let subView = UIView(frame: CGRect(x: 0, y: 40, width: 350.0, height: 45.0))
        subView.addSubview((searchController?.searchBar)!)
        scene.addSubview((searchController?.searchBar)!)
        searchController?.searchBar.sizeToFit()
        
        welcomeLabel.textColor = darkModeToggle ? .white : .black
        resultsViewController?.tableCellSeparatorColor = darkModeToggle ? .black : .white
        resultsViewController?.tableCellBackgroundColor = darkModeToggle ? .black : .white
        resultsViewController?.primaryTextHighlightColor = darkModeToggle ? .white : .black
        resultsViewController?.primaryTextColor = darkModeToggle ? .white : .black
        resultsViewController?.secondaryTextColor = darkModeToggle ? .white : .black
        
        searchController?.searchBar.barTintColor = darkModeToggle ? .black : .white
        searchController?.searchBar.tintColor = darkModeToggle ? .white : .black
        searchController?.searchBar.backgroundColor = darkModeToggle ? .black : .white
        if let textfield = searchController?.searchBar.value(forKey: "searchField") as? UITextField {
            textfield.textColor = darkModeToggle ? .white : .black
        }
        self.view.backgroundColor = darkModeToggle ? .black : .white
        //scene.backgroundColor = darkModeToggle ? .black : .white
        actionSheet.actionTextColor = darkModeToggle ? .white : .black
        actionSheet.actionTintColor = darkModeToggle ? .black : .white
        actionSheet.backgroundColor = darkModeToggle ? .black : .white
        actionSheet.headerDividerColor = darkModeToggle ? .black : .white
        actionSheet.rippleColor = darkModeToggle ? .black : .white
        actionSheet.titleTextColor = darkModeToggle ? .white : .black
        actionSheet.messageTextColor = darkModeToggle ? .white : .black
    }
    
    private func refreshButtons() {
        let buttons = [optionsButton, zoomOutButton, zoomInButton]
        let iconImages = ["gear", "minus", "plus"]
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped(optionsButton:)), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(zoomInButtonTapped(zoomInButton:)), for: .touchUpInside)
        zoomOutButton.addTarget(self, action:
            #selector(zoomOutButtonTapped(zoomOutButton:)), for: .touchUpInside)
        var ycoord: Int = 832
        for button in buttons {
            button.backgroundColor = darkModeToggle ? .darkGray : .white
            button.setElevation(ShadowElevation(rawValue: 6), for: .normal)
            button.frame = CGRect(x: 348, y: ycoord, width: 48, height: 48)
            button.setImage(UIImage(systemName: iconImages[(832 - ycoord) / 57]), for: .normal)
            ycoord -= 57
            self.view.addSubview(button)
        }
    }
    
    private func refreshMap(newLoc: Bool) {
        if (newLoc) {
            camera = GMSCameraPosition.camera(withLatitude: currentLat, longitude: currentLong, zoom: zoom)
            mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        }
        do {
            if let styleURL = Bundle.main.url(forResource: darkModeToggle ? "darkMode" : "standardMode", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        mapView.settings.setAllGesturesEnabled(true)
        self.scene.addSubview(mapView)
        marker = GMSMarker()
        mapView.isTrafficEnabled = trafficToggle
        mapView.isIndoorEnabled = indoorToggle
        marker.position = CLLocationCoordinate2D(latitude: currentLat, longitude: currentLong)
        marker.map = mapView
        resultsViewController?.dismiss(animated: true, completion: nil)
        searchController?.title = ""
    }
    
    @objc private func optionsButtonTapped(optionsButton: MDCFloatingButton){
        optionsButton.collapse(true) {
            optionsButton.expand(true, completion: nil)
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    @objc private func zoomInButtonTapped(zoomInButton: MDCFloatingButton){
        zoomInButton.collapse(true) {
            zoomInButton.expand(true, completion: nil)
        }
        let zoomCamera = GMSCameraUpdate.zoom(by: 3.0)
        mapView.moveCamera(zoomCamera)
        zoom = min(mapView.camera.zoom, 20.0)
    }
    
    @objc private func zoomOutButtonTapped(zoomOutButton: MDCFloatingButton){
        zoomOutButton.collapse(true) {
            zoomOutButton.expand(true, completion: nil)
        }
        let zoomCamera = GMSCameraUpdate.zoom(by: -3.0)
        mapView.moveCamera(zoomCamera)
        zoom = max(mapView.camera.zoom, 0.0)
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
}

extension MainViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didAutocompleteWith place: GMSPlace) {
        currentLat = place.coordinate.latitude
        currentLong = place.coordinate.longitude
        refreshMap(newLoc: true)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didFailAutocompleteWithError error: Error){
        print("Error: ", error.localizedDescription)
    }
}

