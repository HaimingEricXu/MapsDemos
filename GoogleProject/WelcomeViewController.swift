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

class WelcomeViewController: UIViewController, CLLocationManagerDelegate {
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    let locationManager = CLLocationManager()
    @IBOutlet weak var scene: UIView!
    let actionSheet = MDCActionSheetController(title: "Options", message: "Pick a feature")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorization()
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 5.0)
        let mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        mapView.settings.setAllGesturesEnabled(true)
        self.scene.addSubview(mapView)
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.map = mapView
        let floatingButton = MDCFloatingButton()
        floatingButton.setImage(UIImage(systemName: "plus"), for: .normal)
        floatingButton.backgroundColor = .white
        floatingButton.frame = CGRect(x: 348, y: 832, width: 48, height: 48)
        floatingButton.setElevation(ShadowElevation(rawValue: 6), for: .normal)
        floatingButton.addTarget(self, action: #selector(btnFloatingButtonTapped(floatingButton:)), for: .touchUpInside)
        self.view.addSubview(floatingButton)

        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        searchController?.searchBar.sizeToFit()
        definesPresentationContext = true
        let actionOne = MDCActionSheetAction(title: "Search Location",
                                             image: UIImage(systemName: "Home"),
                                             handler: {Void in
                                                self.scene.addSubview((self.searchController?.searchBar)!)
                                             })
        actionSheet.addAction(actionOne)
    }
    
    @objc func btnFloatingButtonTapped(floatingButton: MDCFloatingButton){
        floatingButton.collapse(true) {
            floatingButton.expand(true, completion: nil)
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
}

extension WelcomeViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didAutocompleteWith place: GMSPlace) {
        showMap(loc: place)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didFailAutocompleteWithError error: Error){
        print("Error: ", error.localizedDescription)
    }
    
    func showMap(loc: GMSPlace) {
        let camera = GMSCameraPosition.camera(withLatitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, zoom: 10.0)
        let mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        mapView.settings.setAllGesturesEnabled(true)
        for view in self.scene.subviews{
            view.removeFromSuperview()
        }
        self.scene.addSubview(mapView)
        let marker = GMSMarker()
        mapView.isIndoorEnabled = false
        marker.position = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        marker.map = mapView
        resultsViewController?.dismiss(animated: true, completion: nil)
        searchController?.title = ""
    }
}

