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

class MainViewController: UIViewController, CLLocationManagerDelegate, GMUClusterManagerDelegate {
    
    /// Indicates if the traffic map can be seen
    private var trafficToggle: Bool = false /// encapsulate into TrafficFeatureClass, pass in the map view; toggle on this class
    
    /// Indicates if the map should be in dark mode
    private var darkModeToggle: Bool = false
    private var darkIconXOffset: CGFloat = 50
    private var darkIconYOffset: CGFloat = 868
    private var darkIconDim: CGFloat = 50

    /// Indicates if the map is locked or not; unlocked through a button
    private var lock: Bool = false
            
    /// The heatmap
    private var heatMapLayer: GMUHeatmapTileLayer = GMUHeatmapTileLayer()
    
    /// The general instance to control image representation
    private var imageController = LocationImageGenerator()
    
    /// Indicates if indoor maps should be enabled
    private var indoorToggle: Bool = false
    
    /// Switched between a marker and an image
    private var imageOn: Bool = false
    
    /// If on, only one toggle may be on at a time; the offsets set the location of the indicator
    private var independentToggle: Bool = false
    private var indicatorXOffset: CGFloat = 57
    private var indicatorYOffset: CGFloat = 851
    private var indicatorDim: CGFloat = 20
    
    /// The outlet to call methods in LocationImageGenerator
    private let locationImageController = LocationImageGenerator()
    
    /// The zoom of the camera
    private var zoom: Float = 10.0
    
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
    
    /// Requests access to the user's location
    private let locationManager = CLLocationManager()
    
    /// The general overlay controller for overlay-related features
    private var overlayController = OverlayController()
    
    /// Map setup variables
    private var camera: GMSCameraPosition!
    private var mapView: GMSMapView!
    private var marker: GMSMarker = GMSMarker()
    
    /// Simple UI elements
    @IBOutlet weak private var scene: UIView!
    @IBOutlet weak private var welcomeLabel: UILabel!
    let independentToggleIndicator = UIImageView(image: UIImage(systemName: "1.magnifyingglass"))
    private var generalButton = UIButton()
    
    private var darkModeButton = UIButton()
    private var clearButton = UIButton()
    private var clearXOffset: CGFloat = 0
    private var clearYOffset: CGFloat = 868
    private var clearWidth: CGFloat = 100
    private var clearHeight: CGFloat = 50
    
    private var mapTheme = MapThemes.lightThemeId
    
    /// Marker storage arrays
    private var nearbyLocationMarkers = [GMSMarker]()
    private let nearbyLocationIDs: NSMutableArray = []
    private var heatMapPoints: NSMutableArray = []
    
    /// Define the gradient colors and their start points.
    private var gradientColors = [UIColor.green, UIColor.red]
    private var gradientStartPoints = [NSNumber(0.2), NSNumber(1.0)]
    
    /// Material design elements for UI
    private let actionSheet = MDCActionSheetController(title: "Options", message: "Pick a feature")
    private let optionsButton = MDCFloatingButton()
    private let zoomInButton = MDCFloatingButton()
    private let zoomOutButton = MDCFloatingButton()
    private let currentLocButton = MDCFloatingButton()
    private let infoButton = MDCFloatingButton()
    
    /// The current location of the iPhone using the app
    private let currentClient: GMSPlacesClient = GMSPlacesClient.shared()
    
    /// Places client to get data on the iPhone's current location
    private let placesClient: GMSPlacesClient = GMSPlacesClient.shared()
    
    /// The valid coordinates from the dataset
    private var heatMapList = [GMUWeightedLatLng]()
    
    private var clusterManager: GMUClusterManager!

    /// Sets up the initial screen and adds options to the action sheet
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorization()
        refreshMap(newLoc: true)
        refreshButtons()
        refreshScreen()
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
        let heatMap = MDCActionSheetAction(title: "Show Heat Map For Location", image: UIImage(systemName: "Home"), handler: { Void in
            self.heatMapLayer.map = nil
            self.overlayController.showActivityIndicatory(view: self.view, darkMode: self.darkModeToggle)
            self.generateHeatList()
        })
        let radiusSearch = MDCActionSheetAction(title: "Radius Search", image: UIImage(systemName: "Home"), handler: { Void in
            self.radius()
            //self.lock = true
            let zoomCamera = GMSCameraUpdate.zoom(by: 13.0 - self.zoom)
            self.zoom = 13.0
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
    
    func checkElement(location: CLLocation, completionHandler: @escaping (Bool?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            completionHandler(placemarks?[0].country != nil)
        })
    }
    
    func randomBetween(_ firstNum: CGFloat, _ secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func executeHeatMap(at index: Int = 0) {
        guard index < heatMapPoints.count else {
            heatMapLayer.weightedData = heatMapList
            refreshMap(newLoc: false)
            refreshScreen()
            overlayController.hideActivityIndicatory()
            return
        }
        let lat = (heatMapPoints[index] as! CLLocation).coordinate.latitude
        let long = (heatMapPoints[index] as! CLLocation).coordinate.longitude
        
        //// prebuild the heat-map list
        
        /*checkElement(location: CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))) { land in
            if (land ?? false) {
                let coords = GMUWeightedLatLng(coordinate: CLLocationCoordinate2DMake(CLLocationDegrees(lat), CLLocationDegrees(long)), intensity: 1.0)
                self.heatMapList.append(coords)
            }
            DispatchQueue.main.async {
                self.executeHeatMap(at: index + 1)
            }
        }*/
        let coords = GMUWeightedLatLng(coordinate: CLLocationCoordinate2DMake(CLLocationDegrees(lat), CLLocationDegrees(long)), intensity: 1.0)
        self.heatMapList.append(coords)
        self.executeHeatMap(at: index + 1)
    }
    
    func generateHeatList() {
        var index: Int = 0
        while index < 15000 {
            let lat = randomBetween(CGFloat(Float(currentLat) - 0.08), CGFloat(Float(currentLat) + 0.08))
            let long = randomBetween(CGFloat(Float(currentLong) - 0.08), CGFloat(Float(currentLong) + 0.08))
            index += 1
            heatMapPoints.add(CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long)))
        }
        executeHeatMap()
    }
    
    private func radius() {
        overlayController.drawCircle(mapView: mapView, darkModeToggle: darkModeToggle, lat: currentLat, long: currentLong)
    }
    
    @objc func darkModeActivate(sender: UIButton!) {
        let tempToggle: Bool = !darkModeToggle
        if (independentToggle) {
            toggleOff()
        }
        print("this is just a placeholder for git")
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
        nearbyLocationMarkers.removeAll()
        nearbyLocationIDs.removeAllObjects()
        overlayController.clear()
        clusterManager.clearItems()
        heatMapLayer.map = nil
        heatMapList.removeAll()
        heatMapLayer.weightedData = heatMapList
    }
    
    /// Unlocks the screen
    @objc func exitLock(sender: UIButton!) {
        lock = false
        refreshButtons()
        refreshMap(newLoc: false)
        refreshScreen()
    }
    
    /// Turns off all toggles
    private func toggleOff() {
        trafficToggle = false
        indoorToggle = false
        darkModeToggle = false
    }
    
    /// Function to display a table view of nearby places; user selects one to view close-up
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
                    self.clusterManager.add(POIItem(position: CLLocationCoordinate2DMake(locationMarker.position.latitude + 0.01 * self.randomScale(), locationMarker.position.longitude + 0.01 * self.randomScale()), name: "New Item"))
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
    
    /// Random number generator
    private func randomScale() -> Double {
        return Double(arc4random()) / Double(UINT32_MAX) * 2.0 - 1.0
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
        generalButton.setTitle(lock ? "Exit" : "Clear All", for: .normal)
        if (!lock) {
            generalButton.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        } else {
            generalButton.addTarget(self, action: #selector(exitLock), for: .touchUpInside)
        }
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
            marker.icon = UIImage(systemName: "default_marker.png")
        }
        switch darkModeToggle {
        case true:
            mapTheme = MapThemes.darkThemeId
        default:
            mapTheme = MapThemes.lightThemeId
        }
        let mapID = GMSMapID(identifier: mapTheme)
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
        nearbyIconVisibility(visible: zoom < 17 ? false : true)
        self.mapView.delegate = self
        mapView.settings.setAllGesturesEnabled(true)
        self.scene.addSubview(mapView)
        heatMapLayer.map = mapView
        heatMapLayer.gradient = GMUGradient(colors: gradientColors, startPoints: gradientStartPoints, colorMapSize: 256)
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
extension MainViewController: GMSAutocompleteResultsViewControllerDelegate {
    
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
extension MainViewController: GMSMapViewDelegate {
    
    @objc(mapView:didTapMarker:) func mapView(_: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if (!imageOn) {
            imageOn = true
            locationImageController.viewImage(placeId: currentPlaceID, localMarker: marker)
        } else {
            self.marker.icon = UIImage(systemName: "default_marker.png")
            imageOn = false
        }
        return true
    }
}
