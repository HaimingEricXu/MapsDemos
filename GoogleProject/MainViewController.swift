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
    
    // Indicates if the traffic map can be seen
    private var trafficToggle: Bool = false
    
    // Indicates if the map should be in dark mode
    private var darkModeToggle: Bool = false
    
    // Indicates if indoor maps should be enabled
    private var indoorToggle: Bool = false
    
    // Displays images of a place rather than a simple marker
    private var imageToggle: Bool = false
    
    // Indicates if the map shows pre-set polygons
    private var polygonToggle: Bool = false
    
    // The zoom of the camera
    private var zoom: Float = 10.0
    
    // The location of the camera, which is initially set at Sydney, Australia
    private var currentPlaceID: String = "ChIJP3Sa8ziYEmsRUKgyFmh9AQM"
    private var currentLat: Double = -33.86
    private var currentLong: Double = 151.20
    
    // The search bar and autocomplete screen view controller
    private var resultsViewController: GMSAutocompleteResultsViewController?
    private var searchController: UISearchController?
    private var resultView: UITextView?
    
    // Requests access to the user's location
    private let locationManager = CLLocationManager()
    
    // Map setup variables
    private var camera: GMSCameraPosition!
    private var mapView: GMSMapView!
    private var marker: GMSMarker!
    
    // List of all icons; useful for clearing the map
    private var icons = [GMSMarker]()
    
    // Simple UI elements
    @IBOutlet weak private var scene: UIView!
    @IBOutlet weak private var welcomeLabel: UILabel!
    
    // Material design elements for UI
    private let actionSheet = MDCActionSheetController(title: "Options", message: "Pick a feature")
    private let optionsButton = MDCFloatingButton()
    private let zoomInButton = MDCFloatingButton()
    private let zoomOutButton = MDCFloatingButton()

    // Sets up the initial screen and adds options to the action sheet
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
        actionSheet.addAction(traffic)
        let indoor = MDCActionSheetAction(title: "Toggle Indoor Map",
                                          image: UIImage(systemName: "Home"),
                                          handler: {Void in
                                            self.indoorToggle = !self.indoorToggle
                                            self.currentLat = -33.856689
                                            self.currentLong = 151.21526
                                            self.zoom = 20.0
                                            self.refreshMap(newLoc: true)
                                            self.refreshButtons()
                                            self.refreshScreen()
                                        })
        actionSheet.addAction(indoor)
        let darkMode = MDCActionSheetAction(title: "Toggle Dark Mode",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.darkModeToggle = !self.darkModeToggle
                                                self.refreshMap(newLoc: false)
                                                self.refreshScreen()
                                                self.refreshButtons()
                                        })
        actionSheet.addAction(darkMode)
        let imageMode = MDCActionSheetAction(title: "Toggle Images",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.imageToggle = !self.imageToggle
                                                self.refreshMap(newLoc: false)
                                                self.refreshScreen()
                                        })
        actionSheet.addAction(imageMode)
        let currentLocation = MDCActionSheetAction(title: "Current Location",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.setCurrentLocation()
                                                self.refreshScreen()
                                        })
        actionSheet.addAction(currentLocation)
        let panoramicView = MDCActionSheetAction(title: "Panoramic View",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.openPanorama()
                                        })
        actionSheet.addAction(panoramicView)
        let polygonEnable = MDCActionSheetAction(title: "Toggle Polygons",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.polygonToggle = !self.polygonToggle
                                                self.currentLong = -122.0
                                                self.currentLat = 37.36
                                                self.currentPlaceID = "ChIJc3v8avy1j4ARQCU7rBRXVnw"
                                                self.refreshMap(newLoc: true)
                                        })
        actionSheet.addAction(polygonEnable)
    }
    
    // Draws a pre-set rectangle in specified area; can/will change this to be more flexible and appear in more places
    private func drawPolygon() {
        let rect = GMSMutablePath()
        rect.add(CLLocationCoordinate2D(latitude: 37.36, longitude: -122.0))
        rect.add(CLLocationCoordinate2D(latitude: 37.45, longitude: -122.0))
        rect.add(CLLocationCoordinate2D(latitude: 37.45, longitude: -122.2))
        rect.add(CLLocationCoordinate2D(latitude: 37.36, longitude: -122.2))
        let polygon = GMSPolygon(path: rect)
        polygon.fillColor = UIColor(red: 0.25, green: 0, blue: 0, alpha: 0.05);
        polygon.strokeColor = .black
        polygon.strokeWidth = 2
        polygon.map = mapView
    }
    
    // Clears the map of all markers
    private func removeMarkers(){
        for mark in icons {
            mark.map = nil
        }
    }
    
    // Opens up the StreetViewController for panorama viewing
    private func openPanorama() {
        let vc = storyboard?.instantiateViewController(identifier: "street_vc") as! StreetViewController?
        vc!.long = currentLong
        vc!.lat = currentLat
        vc!.dark = darkModeToggle
        vc!.modalPresentationStyle = .fullScreen
        present(vc!, animated: true)
    }
    
    // Finds the user's current location and sets currentLat, currentLong, and currentPlaceID
    private func setCurrentLocation() {
        let placesClient: GMSPlacesClient = GMSPlacesClient.shared()
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Current Place error: \(error.localizedDescription)")
                return
            }
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.currentLat = place.coordinate.latitude
                    self.currentLong = place.coordinate.longitude
                    self.currentPlaceID = place.placeID!
                    self.refreshMap(newLoc: true)
                }
            }
        })
    }
    
    /* Changes the colors of the buttons, search bar, action sheet, and search results view controller (depending on whether or not dark mode is on)
    * Adds the search bar to the screen
    */
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
        actionSheet.actionTextColor = darkModeToggle ? .white : .black
        actionSheet.actionTintColor = darkModeToggle ? .black : .white
        actionSheet.backgroundColor = darkModeToggle ? .black : .white
        actionSheet.headerDividerColor = darkModeToggle ? .black : .white
        actionSheet.rippleColor = darkModeToggle ? .black : .white
        actionSheet.titleTextColor = darkModeToggle ? .white : .black
        actionSheet.messageTextColor = darkModeToggle ? .white : .black
    }
    
    // Sets up the functionality and location of the FABs
    private func refreshButtons() {
        let buttons = [optionsButton, zoomOutButton, zoomInButton]
        let iconImages = ["gear", "minus", "plus"]
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped(optionsButton:)), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(zoomInButtonTapped(zoomInButton:)), for: .touchUpInside)
        zoomOutButton.addTarget(self, action:
            #selector(zoomOutButtonTapped(zoomOutButton:)), for: .touchUpInside)
        
        /* The scaling factors are as follows:
        *
        * The x-coordinate of the FABs are constant. They are located at 0.85 times the width of the width of view controller (which will change depending on the device) OR 0.1 times the width if we are viewing in indoor mode, since the right hand side contains indoor floor level loggles
        * The y-coordinate of the bottom-most button (options) will be located at 0.9 times the height of the view controller.
        * To find the y-coordinate of the next button, decrement the y-coordinate by 0.07 times the height of the view controller. This value was found via trial/error.
        */
        var ycoord: Double = Double(self.view.frame.size.height) * 0.9
        let xcoord: Double = Double(self.view.frame.size.width) * (indoorToggle && zoom > 19.0 ? 0.1 : 0.85)
        var index: Int = 0
        for button in buttons {
            button.backgroundColor = darkModeToggle ? .darkGray : .white
            button.setElevation(ShadowElevation(rawValue: 6), for: .normal)
            button.frame = CGRect(x: Int(xcoord), y: Int(ycoord), width: 48, height: 48)
            button.setImage(UIImage(systemName: iconImages[index]), for: .normal)
            ycoord -= 0.07 * Double(self.view.frame.size.height)
            index += 1
            self.view.addSubview(button)
        }
    }
    
    // Refreshes the map, allowing changes activated by the toggle to be seen
    private func refreshMap(newLoc: Bool) {
        removeMarkers()
        if (newLoc) {
            camera = GMSCameraPosition.camera(withLatitude: currentLat, longitude: currentLong, zoom: zoom)
            mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        }
        do {
            // USE THE COMMENTED LINE BELOW IN THE FUTURE FOR CLOUD ACCESS
            // let mapID = GMSMapID(identifier: "d9395ca70ad7dcb4")
            // comment the rest of this out when cloud access is fixed
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
        if (polygonToggle) {
            drawPolygon()
        }
        marker = GMSMarker()
        icons.append(marker)
        mapView.isTrafficEnabled = trafficToggle
        mapView.isIndoorEnabled = indoorToggle
        marker.position = CLLocationCoordinate2D(latitude: currentLat, longitude: currentLong)
        marker.map = mapView
        resultsViewController?.dismiss(animated: true, completion: nil)
        searchController?.title = ""
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.photos.rawValue))!
        let placesClient: GMSPlacesClient = GMSPlacesClient.shared()
        if (imageToggle) {
            placesClient.fetchPlace(fromPlaceID: String(currentPlaceID), placeFields: fields,
                                     sessionToken: nil, callback: {
                                        (place: GMSPlace?, error: Error?) in
                                        if let error = error {
                                            print("An error occurred: \(error.localizedDescription)")
                                            return
                                        }
                                        if let place = place {
                                            if (place.photos != nil) {
                                                let photoMetadata: GMSPlacePhotoMetadata = place.photos![0]
                                                placesClient.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
                                                        if let error = error {
                                                            print("Error loading photo metadata: \(error.localizedDescription)")
                                                            return
                                                        } else {
                                                            let size = CGSize(width: 110, height: 110)
                                                            UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
                                                            photo?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                                                            let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                                                            UIGraphicsEndImageContext()
                                                            let tempImage = newImage.opac(alpha: 0.7)
                                                            self.marker.icon = tempImage?.circleMask
                                                        }
                                                    })
                                            } else {
                                                self.marker.icon = UIImage(systemName: "default_marker.png")
                                            }
                                        }
            })
        } else {
            marker.icon = UIImage(systemName: "default_marker.png")
        }
    }
    
    // Opens the action menu
    @objc private func optionsButtonTapped(optionsButton: MDCFloatingButton){
        optionsButton.collapse(true) {
            optionsButton.expand(true, completion: nil)
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    // Zoom in, changes zoom variable
    @objc private func zoomInButtonTapped(zoomInButton: MDCFloatingButton){
        zoomInButton.collapse(true) {
            zoomInButton.expand(true, completion: nil)
        }
        let zoomCamera = GMSCameraUpdate.zoom(by: 1.0)
        mapView.moveCamera(zoomCamera)
        zoom = min(mapView.camera.zoom, 20.0)
        refreshButtons()
    }
    
    // Zoom out, changes zoom variable
    @objc private func zoomOutButtonTapped(zoomOutButton: MDCFloatingButton){
        zoomOutButton.collapse(true) {
            zoomOutButton.expand(true, completion: nil)
        }
        let zoomCamera = GMSCameraUpdate.zoom(by: -1.0)
        mapView.moveCamera(zoomCamera)
        zoom = max(mapView.camera.zoom, 0.0)
        refreshButtons()
    }
    
    // Requests the user's location
    private func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
}

// Extension for the search view controller and results view controller to interact
extension MainViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    // Once a location is confirmed, change currentLat and currentLong to reflect that location; updates the map to show that location
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didAutocompleteWith place: GMSPlace) {
        currentLat = place.coordinate.latitude
        currentLong = place.coordinate.longitude
        currentPlaceID = place.placeID!
        refreshMap(newLoc: true)
    }
    
    // Default error message
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didFailAutocompleteWithError error: Error){
        print("Error: ", error.localizedDescription)
    }
}

// Extensions to make the marker images circular and translucent
extension UIImage {
    
    // Sets whatever image to be in a circular frame
    var circleMask: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: .init(origin: .init(x: 0, y: 0), size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 5
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        imageView.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // Sets opacity to given alpha value
    func opac(alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
