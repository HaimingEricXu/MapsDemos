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
import MaterialComponents.MaterialBanner

// map feature -- different features
class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    // Indicates if the traffic map can be seen
    private var trafficToggle: Bool = false // encapsulate into TrafficFeatureClass, pass in the map view; toggle on this class
    
    // Indicates if the map should be in dark mode
    private var darkModeToggle: Bool = false
    
    // Indicates if indoor maps should be enabled
    private var indoorToggle: Bool = false
    
    // Switched between a marker and an image
    private var imageOn: Bool = false
    
    // If on, only one toggle may be on at a time
    private var independentToggle: Bool = false
    
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
    private var marker: GMSMarker = GMSMarker()
    
    // Simple UI elements
    @IBOutlet weak private var scene: UIView!
    @IBOutlet weak private var welcomeLabel: UILabel!
    private var darkModeButton = UIButton()
    private var clearButton = UIButton()
    
    // Marker storage arrays
    var nearbyLocationMarkers = [GMSMarker]()
    let nearbyLocationIDs: NSMutableArray = []
    
    // Material design elements for UI
    private let actionSheet = MDCActionSheetController(title: "Options", message: "Pick a feature")
    private let optionsButton = MDCFloatingButton()
    private let zoomInButton = MDCFloatingButton()
    private let zoomOutButton = MDCFloatingButton()
    private let currentLocButton = MDCFloatingButton()

    // Sets up the initial screen and adds options to the action sheet
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorization()
        refreshMap(newLoc: true)
        refreshButtons()
        refreshScreen()
        let independence = MDCActionSheetAction(title: "Toggle Independent Features",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.independentToggle = !self.independentToggle
                                                if (self.independentToggle) {
                                                    self.toggleOff()
                                                }
                                                self.refreshButtons()
                                                self.refreshMap(newLoc: false)
                                                self.refreshScreen()
                                        })
        let traffic = MDCActionSheetAction(title: "Toggle Traffic Overlay",
                                           image: UIImage(systemName: "Home"),
                                           handler: {Void in
                                            if (self.independentToggle) {
                                                self.toggleOff()
                                            }
                                            self.trafficToggle = !self.trafficToggle
                                            self.refreshMap(newLoc: false)
                                            self.refreshButtons()
                                            self.refreshScreen()
                                        })
        let indoor = MDCActionSheetAction(title: "Toggle Indoor Map",
                                          image: UIImage(systemName: "Home"),
                                          handler: {Void in
                                            if (self.independentToggle) {
                                                self.toggleOff()
                                            }
                                            self.indoorToggle = !self.indoorToggle
                                            if (self.indoorToggle) {
                                                self.currentLat = -33.856689
                                                self.currentLong = 151.21526
                                                self.zoom = 20.0
                                            }
                                            self.refreshMap(newLoc: true)
                                            self.refreshButtons()
                                            self.refreshScreen()
                                        })
        let nearbyRecs = MDCActionSheetAction(title: "Nearby Recommendations",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.showNearby()
                                                self.refreshButtons()
                                                self.refreshScreen()
                                        })
        let panoramicView = MDCActionSheetAction(title: "Panoramic View",
                                            image: UIImage(systemName: "Home"),
                                            handler: {Void in
                                                self.openPanorama()
                                        })
        let actions: NSMutableArray = [independence, traffic, indoor, nearbyRecs, panoramicView]
        for a in actions {
            actionSheet.addAction(a as! MDCActionSheetAction)
        }
        // find points of interest in this circle
        // drag the circle to include POIs within the circle (ADVANCED FEATURE)
    }
    
    @objc func darkModeActivate(sender: UIButton!) {
        let tempToggle: Bool = !darkModeToggle
        if (independentToggle) {
            toggleOff()
        }
        darkModeToggle = tempToggle
        refreshMap(newLoc: false, darkModeSwitch: true)
        refreshScreen()
        refreshButtons()
    }
    
    @objc func clearAll(sender: UIButton!) {
        for x in nearbyLocationMarkers {
            x.map = nil
        }
    }
    
    // Turns off all toggles
    private func toggleOff() {
        trafficToggle = false
        indoorToggle = false
        darkModeToggle = false
    }
    
    // Function to display a table view of nearby places; user selects one to view close-up
    private func showNearby() {
        let current: GMSPlacesClient = GMSPlacesClient.shared()
        current.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Current Place error: \(error.localizedDescription)")
                return
            }
            if let placeLikelihoodList = placeLikelihoodList {
                var counter: Int = 0
                var first: Bool = true
                for loc in placeLikelihoodList.likelihoods {
                    if (first) {
                        first = false
                        continue
                    }
                    let temp: GMSMarker = GMSMarker()
                    temp.position = CLLocationCoordinate2D(latitude: loc.place.coordinate.latitude, longitude: loc.place.coordinate.longitude)
                    self.nearbyLocationMarkers.append(temp)
                    self.nearbyLocationIDs.add(loc.place.placeID!)
                }
                for x in self.nearbyLocationMarkers {
                    self.viewImage(placeLoc: self.nearbyLocationIDs[counter] as! String, localMarker: x, tapped: false)
                    x.map = self.mapView
                    counter += 1
                }
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
                            self.zoom = 20
                            self.refreshMap(newLoc: true)
                            self.refreshScreen()
                        }
                    }
                })
            }
        })
        definesPresentationContext = true
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
        polygon.strokeColor = darkModeToggle ? .white : .black
        polygon.strokeWidth = 2
        polygon.map = mapView
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
    
    /* Changes the colors of the buttons, search bar, action sheet, and search results view controller (depending on whether or not dark mode is on)
    * Adds the search bar to the screen
    */
    private func refreshScreen() {
        if (independentToggle) {
            let image = UIImage(systemName: "1.magnifyingglass")
            let imageView = UIImageView(image: image!)
            imageView.frame = CGRect(x: self.view.frame.size.width - 57, y: self.view.frame.size.height - 851, width: 20, height: 20)
            imageView.tintColor = darkModeToggle ? .white : .red
            self.view.addSubview(imageView)
        }
        // Sets up the search bar and results view controller
        self.view.backgroundColor = darkModeToggle ? .darkGray : .white
        self.scene.backgroundColor = darkModeToggle ? .darkGray : .white
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        searchController?.searchBar.sizeToFit()
        definesPresentationContext = true
        scene.addSubview((searchController?.searchBar)!)
        searchController?.searchBar.sizeToFit()
        
        // Changes the results view controller and search bar to be the right color
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
        
        // Sets other view elements to the right colors
        welcomeLabel.textColor = darkModeToggle ? .white : .black
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
        darkModeButton.frame = CGRect(x: self.view.frame.size.width - 50, y: self.view.frame.size.height - 868, width: 50, height: 50)
        darkModeButton.setImage(UIImage(systemName: darkModeToggle ? "sun.min.fill" : "moon.stars.fill"), for: .normal)
        darkModeButton.tintColor = darkModeToggle ? .yellow : .blue
        darkModeButton.addTarget(self, action: #selector(darkModeActivate), for: .touchUpInside)
        self.view.addSubview(darkModeButton)
        
        clearButton.frame = CGRect(x: 0, y: self.view.frame.size.height - 868, width: 100, height: 50)
        clearButton.setTitleColor(darkModeToggle ? .white : .blue, for: .normal)
        clearButton.setTitle("Clear All", for: .normal)
        clearButton.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        self.view.addSubview(clearButton)
        
        let buttons = [optionsButton, zoomOutButton, zoomInButton, currentLocButton]
        let iconImages = ["gear", "minus", "plus", "location"]
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped(optionsButton:)), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(zoomInButtonTapped(zoomInButton:)), for: .touchUpInside)
        zoomOutButton.addTarget(self, action:
            #selector(zoomOutButtonTapped(zoomOutButton:)), for: .touchUpInside)
        currentLocButton.addTarget(self, action:
            #selector(goToCurrent(currentLocButton:)), for: .touchUpInside)
        
        /* The scaling factors are as follows:
        *
        * The x-coordinate of the FABs are constant. They are located at 0.85 times the width of the width of view controller (which will change depending on the device) OR 0.1 times the width if we are viewing in indoor mode, since the right hand side contains indoor floor level loggles
        * The y-coordinate of the bottom-most button (options) will be located at 0.9 times the height of the view controller.
        * To find the y-coordinate of the next button, decrement the y-coordinate by 0.07 times the height of the view controller. This value was found via trial/error.
        */
        var ycoord: Double = Double(self.view.frame.size.height) * 0.9
        let xcoord: Double = Double(self.view.frame.size.width) * (indoorToggle && zoom > 16.0 ? 0.1 : 0.85)
        var index: Int = 0
        for button in buttons {
            button.isHidden = false
            button.backgroundColor = darkModeToggle ? .darkGray : .white
            button.setElevation(ShadowElevation(rawValue: 6), for: .normal)
            button.frame = CGRect(x: Int(xcoord), y: Int(ycoord), width: 48, height: 48)
            button.setImage(UIImage(systemName: iconImages[index]), for: .normal)
            ycoord -= 0.07 * Double(self.view.frame.size.height)
            index += 1
            self.view.addSubview(button)
        }
        darkModeButton.isHidden = false
    }
    
    // Refreshes the map, allowing changes activated by the toggle to be seen
    private func refreshMap(newLoc: Bool, darkModeSwitch: Bool = false) {
        if (newLoc) {
            imageOn = false
            marker.icon = UIImage(systemName: "default_marker.png")
        }
        let mapID = darkModeToggle ? GMSMapID(identifier: "d9395ca70ad7dcb4") : GMSMapID(identifier: "209da1a703f62076")
        if (newLoc) {
            camera = GMSCameraPosition.camera(withLatitude: currentLat, longitude: currentLong, zoom: zoom)
            if (mapView == nil) {
                mapView = GMSMapView(frame: self.view.frame, mapID: mapID, camera: camera)
            } else {
                mapView.animate(to: camera)
            }
        }
        if (darkModeSwitch) {
            mapView = GMSMapView(frame: self.view.frame, mapID: mapID, camera: camera)
        }
        self.mapView.delegate = self
        mapView.settings.setAllGesturesEnabled(true)
        self.scene.addSubview(mapView)
        mapView.isTrafficEnabled = trafficToggle
        mapView.isIndoorEnabled = indoorToggle
        marker.position = CLLocationCoordinate2D(latitude: currentLat, longitude: currentLong)
        marker.map = mapView
        resultsViewController?.dismiss(animated: true, completion: nil)
        searchController?.title = ""
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
        let zoomCamera = GMSCameraUpdate.zoom(by: 2.0)
        mapView.moveCamera(zoomCamera)
        zoom = min(mapView.camera.zoom, 20.0)
        refreshButtons()
    }
    
    // Zoom out, changes zoom variable
    @objc private func zoomOutButtonTapped(zoomOutButton: MDCFloatingButton){
        zoomOutButton.collapse(true) {
            zoomOutButton.expand(true, completion: nil)
        }
        let zoomCamera = GMSCameraUpdate.zoom(by: -2.0)
        mapView.moveCamera(zoomCamera)
        zoom = max(mapView.camera.zoom, 0.0)
        refreshButtons()
    }
    
    @objc private func goToCurrent(currentLocButton: MDCFloatingButton){
        currentLocButton.collapse(true) {
            currentLocButton.expand(true, completion: nil)
        }
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
                    self.refreshScreen()
                }
            }
        })
        refreshButtons()
    }
    
    // Sets a marker's icon to a place's image, if it has one
    private func viewImage(placeLoc: String, localMarker: GMSMarker, tapped: Bool = true) {
        let placesClient: GMSPlacesClient = GMSPlacesClient.shared()
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.photos.rawValue))!
        placesClient.fetchPlace(fromPlaceID: String(placeLoc), placeFields: fields,
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
                                                        localMarker.icon = tempImage?.circleMask
                                                        if (tapped) {
                                                            self.imageOn = true
                                                        }
                                                    }
                                                })
                                        } else {
                                            localMarker.icon = UIImage(systemName: "eye.slash.fill")
                                            localMarker.icon?.withTintColor(.black)
                                        }
                                    }
        })
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

extension MainViewController: GMSMapViewDelegate {
    
    @objc(mapView:didTapMarker:) func mapView(_: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if (!imageOn) {
            viewImage(placeLoc: currentPlaceID, localMarker: marker)
        } else {
            self.marker.icon = UIImage(systemName: "default_marker.png")
            imageOn = false
        }
        return true
    }
}
