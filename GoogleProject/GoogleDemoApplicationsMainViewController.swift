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
import GoogleMapsUtils
import GooglePlaces
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialActionSheet
import MaterialComponents.MaterialBanner
import MaterialComponents.MaterialCards

class GoogleDemoApplicationsMainViewController: UIViewController, CLLocationManagerDelegate, GMUClusterManagerDelegate {
        
    private let initialZoom: Float = 10.0
    
    /// Indicates if the traffic map can be seen
    private var trafficToggle: Bool = false
    
    /// Indicates if indoor maps should be enabled
    private var indoorToggle: Bool = false
    
    /// If on, only one toggle may be on at a time; the offsets set the location of the indicator
    private var independentToggle: Bool = false
    
    /// Indicates if the map should be in dark mode
    private var darkModeToggle: Bool = false
    
    /// Indicates if the heat map should appear
    private var heatMapToggle = false
    
    /// Dark mode button and properties; may change depending on the device
    private var darkModeButton = UIButton()
    private var darkIconXOffset: CGFloat = 50
    private var darkIconYOffset: CGFloat = 868
    private var darkIconDim: CGFloat = 50
    
    /// The heat map,  its data set, and other color setup
    private var heatMapLayer: GMUHeatmapTileLayer = GMUHeatmapTileLayer()
    private var heatMapPoints = [GMUWeightedLatLng]()
    private var gradientColors = [UIColor.green, UIColor.red]
    private var gradientStartheatMapPoints = [NSNumber(0.2), NSNumber(1.0)]
    
    /// Requests access to the user's location
    private let locationManager = CLLocationManager()
    
    /// The general overlay controller for overlay-related features
    private var overlayController = OverlayController()
    
    /// The outlet to call methods in LocationImageGenerator
    private let locationImageController = LocationImageGenerator()
    
    /// The current location of the iPhone using the app
    private let currentClient: GMSPlacesClient = GMSPlacesClient.shared()
    
    /// Places client to get data on the iPhone's current location
    private let placesClient: GMSPlacesClient = GMSPlacesClient.shared()
    
    /// The cluster manager for the nearby recommendations feature; clusters icons to reduce clutter
    private var clusterManager: GMUClusterManager!
            
    /// Switches between a marker and an image
    private var imageOn: Bool = false
    
    /// Indepedent features indicator and properies; may change depending on the device
    private let independentToggleIndicator = UIImageView(image: UIImage(systemName: "1.magnifyingglass"))
    private var indicatorXOffset: CGFloat = 57
    private var indicatorYOffset: CGFloat = 851
    private var indicatorDim: CGFloat = 20
    
    /// The zoom of the camera
    private var zoom: Float!
    
    // The maximum zoom value; useful for indoor maps
    private let maximumZoom: Float = 20.0
    
    /// The location of the camera, which is initially set at Sydney, Australia
    private var currentPlaceID: String = "ChIJP3Sa8ziYEmsRUKgyFmh9AQM"
    private var currentLat: Double = -33.86
    private var currentLong: Double = 151.20
    
    /// When the user selects indoor toggle, the map goes to the interior of Sydney Opera House as default
    private let sydneyOperaHouseLat: Double = -33.856689
    private let sydneyOperaHouseLong: Double = 151.21526
    
    /// The search bar and autocomplete screen view controller
    private var resultsViewController: GMSAutocompleteResultsViewController?
    private var searchController: UISearchController?
    private var resultView: UITextView?
    
    /// Map setup variables
    private var camera: GMSCameraPosition!
    private var mapView: GMSMapView!
    private var marker: GMSMarker = GMSMarker()
    
    /// Simple UI elements
    @IBOutlet weak private var scene: UIView!
    @IBOutlet weak private var welcomeLabel: UILabel!
    private var generalButton = UIButton()
    private var clearButton = UIButton()
    private var clearXOffset: CGFloat = 0
    private var clearYOffset: CGFloat = 868
    private var clearWidth: CGFloat = 100
    private var clearHeight: CGFloat = 50
    
    /// The map theme (dark mode or light mode); initially set to light mode
    private var mapTheme = MapThemes.lightThemeId
    
    /// Marker storage arrays
    private var nearbyLocationMarkers = [GMSMarker]()
    private let nearbyLocationIDs: NSMutableArray = []
    private var radiusMarkers = [GMSMarker]()
    
    /// Material design elements for UI
    private let actionSheet = MDCActionSheetController(title: "Options", message: "Pick a feature")
    private let optionsButton = MDCFloatingButton()
    private let zoomInButton = MDCFloatingButton()
    private let zoomOutButton = MDCFloatingButton()
    private let currentLocButton = MDCFloatingButton()
    private let infoButton = MDCFloatingButton()

    /// Sets up the initial screen and adds options to the action sheet
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorization()
        zoom = initialZoom

        refreshMap(newLoc: true)
        refreshButtons()
        refreshScreen()
        heatMapLayer.map = mapView
        executeHeatMap()
        
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        clusterManager.setDelegate(self, mapDelegate: self)
        
        let independence = MDCActionSheetAction(title: "Toggle Independent Features", image: nil, handler: { Void in
            self.independentToggle = !self.independentToggle
            if (self.independentToggle) {
                self.toggleOff()
            }
            self.refreshButtons()
            self.refreshMap(newLoc: false, darkModeSwitch: true)
            self.refreshScreen()
        })
        let traffic = MDCActionSheetAction(title: "Toggle Traffic Overlay", image: nil, handler: { Void in
            let darkModeTemp = self.darkModeToggle
            let trafficTemp = self.trafficToggle
            if (self.independentToggle) {
                self.toggleOff()
            }
            self.trafficToggle = !trafficTemp
            self.refreshMap(newLoc: false, darkModeSwitch: self.independentToggle && darkModeTemp ? true : false)
            self.refreshButtons()
            self.refreshScreen()
        })
        let indoor = MDCActionSheetAction(title: "Toggle Indoor Map", image: nil, handler: { Void in
            let darkModeTemp = self.darkModeToggle
            let indoorTemp = self.trafficToggle
            if (self.independentToggle) {
                self.toggleOff()
            }
            self.indoorToggle = !indoorTemp
            if (self.indoorToggle) {
                self.currentLat = self.sydneyOperaHouseLat
                self.currentLong = self.sydneyOperaHouseLong
                self.zoom = self.maximumZoom
            }
            self.refreshMap(newLoc: true, darkModeSwitch: self.independentToggle && darkModeTemp ? true : false)
            self.refreshButtons()
            self.refreshScreen()
        })
        let nearbyRecs = MDCActionSheetAction(title: "Nearby Recommendations", image: nil, handler: { Void in
            self.showNearby()
            self.refreshButtons()
            self.refreshScreen()
        })
        let panoramicView = MDCActionSheetAction(title: "Panoramic View", image: nil, handler: { Void in
            self.openPanorama()
        })
        let heatMap = MDCActionSheetAction(title: "Toggle Heat Map", image: UIImage(systemName: "Home"), handler: { Void in
            if (self.independentToggle) {
                self.toggleOff()
            }
            self.heatMapToggle = !self.heatMapToggle
            if (self.heatMapToggle) {
                self.heatMapLayer.weightedData = self.heatMapPoints
                self.heatMapLayer.map = self.mapView
            } else {
                self.heatMapLayer.weightedData = []
                self.heatMapLayer.map = nil
            }
            self.refreshButtons()
            self.refreshMap(newLoc: false, darkModeSwitch: true)
            self.refreshScreen()
        })
        let radiusSearch = MDCActionSheetAction(title: "Radius Search", image: UIImage(systemName: "Home"), handler: { Void in
            self.radius()
            let zoomCamera = GMSCameraUpdate.zoom(by: 14.0 - self.zoom)
            self.zoom = 14.0
            self.mapView.moveCamera(zoomCamera)
            self.refreshButtons()
            self.refreshMap(newLoc: false)
            self.refreshScreen()
        })
        
        let actions: NSMutableArray = [independence, traffic, heatMap, indoor, nearbyRecs, panoramicView, radiusSearch]
        for a in actions {
            actionSheet.addAction(a as! MDCActionSheetAction)
        }
    }
    
    private func clusterManager(clusterManager: GMUClusterManager, didTapCluster cluster: GMUCluster) {
        let newCamera = GMSCameraPosition.camera(withTarget: cluster.position, zoom: mapView.camera.zoom + 1)
        let update = GMSCameraUpdate.setCamera(newCamera)
        mapView.moveCamera(update)
    }
    
    func executeHeatMap() {
        do {
            if let path = Bundle.main.url(forResource: "dataset", withExtension: "json") {
                let data = try Data(contentsOf: path)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [[String: Any]] {
                    for item in object {
                        let lat = item["lat"]
                        let lng = item["lng"]
                        let coords = GMUWeightedLatLng(coordinate: CLLocationCoordinate2DMake(lat as! CLLocationDegrees, lng as! CLLocationDegrees), intensity: 1.0)
                        heatMapPoints.append(coords)
                    }
                } else {
                    print("Could not read the JSON.")
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func radius() {
        for marker in radiusMarkers {
            marker.map = nil
        }
        radiusMarkers.removeAll()
        overlayController.drawCircle(mapView: mapView, darkModeToggle: darkModeToggle, lat: currentLat, long: currentLong)
        for _ in 0...10 {
            let tempLat = Float(currentLat) + Float.random(in: -0.01..<0.01)
            let tempLong = Float(currentLong) + Float.random(in: -0.01..<0.01)
            overlayController.geocode(latitude: Double(tempLat), longitude: Double(tempLong)) { (placemark, error, pid) in
                DispatchQueue.main.async {
                    let tempMarker: GMSMarker = GMSMarker()
                    if (pid.count >= 4) {
                        print("hi")
                        let start = pid.index(pid.startIndex, offsetBy: 4)
                        let range = start..<pid.endIndex
                        let officialPid = pid[range]
                        tempMarker.position = CLLocationCoordinate2D(latitude: Double(tempLat), longitude: Double(tempLong))
                        self.locationImageController.viewImage(placeId: String(officialPid), localMarker: tempMarker)
                        tempMarker.map = self.mapView
                        self.radiusMarkers.append(tempMarker)
                    }
                }
            }
        }
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
    
    /// Clears all icon images and overlays
    @objc func clearAll(sender: UIButton!) {
        for marker in nearbyLocationMarkers {
            marker.map = nil
        }
        for marker in radiusMarkers {
            marker.map = nil
        }
        radiusMarkers.removeAll()
        nearbyLocationMarkers.removeAll()
        nearbyLocationIDs.removeAllObjects()
        overlayController.clear()
        clusterManager.clearItems()
    }
    
    /// Turns off all toggles
    private func toggleOff() {
        trafficToggle = false
        indoorToggle = false
        darkModeToggle = false
        heatMapToggle = false
        heatMapLayer.weightedData = []
        heatMapLayer.map = nil
    }
    
    /// ADD comments about how the code and features work
    
    /// Function to display nearby heatMapPoints of interest
    private func showNearby() {
        currentClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            guard error == nil else {
                print("Current place error: \(error?.localizedDescription ?? "")")
                return
            }
            if let placeLikelihoodList = placeLikelihoodList {
                var counter: Int = 0
                var first: Bool = true
                for loc in placeLikelihoodList.likelihoods {
                    
                    /// We need to skip the first element because the first element is the actual location of the phone, while we want to take the nearby locations
                    /// Possibly add a blue blinking marker for current location to differentiate
                    if (first) {
                        first = false
                        continue
                    }
                    let temp: GMSMarker = GMSMarker()
                    temp.position = CLLocationCoordinate2D(latitude: loc.place.coordinate.latitude, longitude: loc.place.coordinate.longitude)
                    self.nearbyLocationMarkers.append(temp)
                    self.nearbyLocationIDs.add(loc.place.placeID!)
                }
                for locationMarker in self.nearbyLocationMarkers {
                    self.locationImageController.viewImage(placeId: self.nearbyLocationIDs[counter] as! String, localMarker: locationMarker, tapped: false)
                    locationMarker.map = self.mapView
                    counter += 1
                    self.clusterManager.add(POIItem(position: CLLocationCoordinate2DMake(locationMarker.position.latitude, locationMarker.position.longitude), name: "New Item"))
                }
                self.placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
                    guard error == nil && placeLikelihoodList != nil else {
                        print("Current place error: \(error?.localizedDescription ?? "")")
                        return
                    }
                    let place = placeLikelihoodList?.likelihoods.first?.place
                    if let place = place {
                        self.currentLat = place.coordinate.latitude
                        self.currentLong = place.coordinate.longitude
                        self.currentPlaceID = place.placeID!
                        self.zoom = 20
                        self.refreshMap(newLoc: true)
                        self.refreshScreen()
                    }
                })
            }
        })
        definesPresentationContext = true
    }
    
    
    private func nearbyIconVisibility(visible: Bool) {
        for marker in nearbyLocationMarkers {
            marker.map = visible ? mapView : nil
        }
    }
    
    
    /// Opens up the StreetViewController for panorama viewing
    private func openPanorama() {
        /// There shouldn't be the need for an optional for vc, as this is hardcoded to depict StreetViewController
        let vc = storyboard?.instantiateViewController(identifier: "street_vc") as! StreetViewController
        vc.setLat(newLat: currentLat)
        vc.setLong(newLong: currentLong)
        vc.setDark(darkMode: darkModeToggle)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    /* Changes the colors of the buttons, search bar, action sheet, and search results view controller (depending on whether or not dark mode is on)
    * Adds the search bar to the screen
    */
    private func refreshScreen() {
        if (independentToggle) {
            independentToggleIndicator.isHidden = false
            independentToggleIndicator.frame = CGRect(x: self.view.frame.size.width - indicatorXOffset, y: self.view.frame.size.height - indicatorYOffset, width: indicatorDim, height: indicatorDim)
            independentToggleIndicator.tintColor = darkModeToggle ? .white : .red
            self.view.addSubview(independentToggleIndicator)
        } else {
            independentToggleIndicator.isHidden = true
        }
        
        /// Sets up the search bar and results view controller
        view.backgroundColor = darkModeToggle ? .darkGray : .white
        scene.backgroundColor = darkModeToggle ? .darkGray : .white
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        searchController?.searchBar.sizeToFit()
        definesPresentationContext = true
        scene.addSubview((searchController?.searchBar)!)
        searchController?.searchBar.sizeToFit()
        
        /// Changes the results view controller and search bar to be the right color
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
        
        /// Sets other view elements to the right colors
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
    
    /// Sets up the functionality and location of the FABs
    private func refreshButtons() {
        darkModeButton.frame = CGRect(x: self.view.frame.size.width - darkIconXOffset, y: self.view.frame.size.height - darkIconYOffset, width: darkIconDim, height: darkIconDim)
        darkModeButton.setImage(UIImage(systemName: darkModeToggle ? "sun.min.fill" : "moon.stars.fill"), for: .normal)
        darkModeButton.tintColor = darkModeToggle ? .yellow : .blue
        darkModeButton.addTarget(self, action: #selector(darkModeActivate), for: .touchUpInside)
        self.view.addSubview(darkModeButton)
        
        generalButton.frame = CGRect(x: 0, y: self.view.frame.size.height - 868, width: 100, height: 50)
        generalButton.setTitleColor(darkModeToggle ? .white : .blue, for: .normal)
        generalButton.setTitle( "Clear All", for: .normal)
        generalButton.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        self.view.addSubview(generalButton)
        
        clearButton.frame = CGRect(x: clearXOffset, y: self.view.frame.size.height - clearYOffset, width: clearWidth, height: clearHeight)
        clearButton.setTitleColor(darkModeToggle ? .white : .blue, for: .normal)
        clearButton.setTitle("Clear All", for: .normal)
        clearButton.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        self.view.addSubview(clearButton)
        
        let buttons = [optionsButton, zoomOutButton, zoomInButton, currentLocButton, infoButton]
        let iconImages = ["gear", "minus", "plus", "location", "info"]
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped(optionsButton:)), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(zoomInButtonTapped(zoomInButton:)), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(zoomOutButtonTapped(zoomOutButton:)), for: .touchUpInside)
        currentLocButton.addTarget(self, action: #selector(goToCurrent(currentLocButton:)), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoButtonTapped(infoButton:)), for: .touchUpInside)
        
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
    
    /// Refreshes the map, allowing changes activated by the toggle to be seen
    private func refreshMap(newLoc: Bool, darkModeSwitch: Bool = false) {
        if (newLoc) {
            imageOn = false
            marker.icon = UIImage(systemName: "button_my_location.png")
        }
        switch darkModeToggle {
        case true:
            mapTheme = MapThemes.darkThemeId
        default:
            mapTheme = MapThemes.lightThemeId
        }
        let mapID = GMSMapID(identifier: mapTheme)
        camera = GMSCameraPosition.camera(withLatitude: currentLat, longitude: currentLong, zoom: zoom)
        if (newLoc) {
            if (mapView == nil) {
                mapView = GMSMapView(frame: self.view.frame, mapID: mapID, camera: camera)
            } else {
                mapView.animate(to: camera)
            }
        }
        if (darkModeSwitch) {
            mapView = GMSMapView(frame: self.view.frame, mapID: mapID, camera: camera)
        }
        nearbyIconVisibility(visible: zoom < 17 ? false : true)
        self.mapView.delegate = self
        mapView.settings.setAllGesturesEnabled(true)
        self.scene.addSubview(mapView)
        heatMapLayer.map = mapView
        heatMapLayer.gradient = GMUGradient(colors: gradientColors, startPoints: gradientStartheatMapPoints, colorMapSize: 256)
        mapView.isTrafficEnabled = trafficToggle
        mapView.isIndoorEnabled = indoorToggle
        marker.position = CLLocationCoordinate2D(latitude: currentLat, longitude: currentLong)
        marker.map = mapView
        resultsViewController?.dismiss(animated: true, completion: nil)
        searchController?.title = ""
    }
    
    /// Opens the action menu
    @objc private func optionsButtonTapped(optionsButton: MDCFloatingButton){
        optionsButton.collapse(true) {
            optionsButton.expand(true, completion: nil)
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    /// Zoom in, changes zoom variable
    @objc private func zoomInButtonTapped(zoomInButton: MDCFloatingButton){
        zoomInButton.collapse(true) {
            zoomInButton.expand(true, completion: nil)
        }
        let zoomCamera = GMSCameraUpdate.zoom(by: 2.0)
        mapView.moveCamera(zoomCamera)
        zoom = min(mapView.camera.zoom, maximumZoom)
        refreshButtons()
        refreshMap(newLoc: false)
        refreshScreen()
    }
    
    /// Zoom out, changes zoom variable
    @objc private func zoomOutButtonTapped(zoomOutButton: MDCFloatingButton){
        zoomOutButton.collapse(true) {
            zoomOutButton.expand(true, completion: nil)
        }
        let zoomCamera = GMSCameraUpdate.zoom(by: -2.0)
        mapView.moveCamera(zoomCamera)
        zoom = max(mapView.camera.zoom, 0)
        refreshButtons()
        refreshMap(newLoc: false)
        refreshScreen()
    }
    
    /// Moves the view to the phone's current location
    @objc private func goToCurrent(currentLocButton: MDCFloatingButton){
        currentLocButton.collapse(true) {
            currentLocButton.expand(true, completion: nil)
        }
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            guard error == nil && placeLikelihoodList != nil else {
                print("Current place error: \(error?.localizedDescription ?? "")")
                return
            }
            guard placeLikelihoodList?.likelihoods.first != nil else {
                print("No current place.")
                return
            }
            let place = placeLikelihoodList?.likelihoods.first?.place
            guard place != nil else {
                print("Current place error: \(error?.localizedDescription ?? "")")
                return
            }
            self.currentLat = Double(place?.coordinate.latitude ?? 0.0)
            self.currentLong = Double(place?.coordinate.longitude ?? 0.0)
            self.currentPlaceID = place?.placeID ?? "None"
            self.refreshMap(newLoc: true)
            self.refreshScreen()
        })
        refreshButtons()
    }
    
    @objc private func infoButtonTapped(infoButton: MDCFloatingButton){
        infoButton.collapse(true) {
            infoButton.expand(true, completion: nil)
        }
        let popOverVC = storyboard?.instantiateViewController(withIdentifier: "popup_vc") as! PopUpViewController
        popOverVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        popOverVC.setLocation(loc: currentPlaceID)
        popOverVC.setLat(lat: currentLat)
        popOverVC.setLong(long: currentLong)
        self.present(popOverVC, animated: true)
    }
    
    /// Requests the user's location
    private func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
}

/// Extension for the search view controller and results view controller to interact
extension GoogleDemoApplicationsMainViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    /// Once a location is confirmed, change currentLat and currentLong to reflect that location; updates the map to show that location
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didAutocompleteWith place: GMSPlace) {
        currentLat = place.coordinate.latitude
        currentLong = place.coordinate.longitude
        currentPlaceID = place.placeID!
        refreshMap(newLoc: true)
    }
    
    /// Default error message
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didFailAutocompleteWithError error: Error){
        print("Error: ", error.localizedDescription)
    }
}

/// Allows the location icons to be clicked
extension GoogleDemoApplicationsMainViewController: GMSMapViewDelegate {
    
    @objc(mapView:didTapMarker:) func mapView(_: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if (marker.position.latitude == currentLat && marker.position.longitude == currentLong) {
            if (!imageOn) {
                imageOn = true
                locationImageController.viewImage(placeId: currentPlaceID, localMarker: marker)
            } else {
                self.marker.icon = UIImage(systemName: "default_marker.png")
                imageOn = false
            }
        }
        return true
    }
}
