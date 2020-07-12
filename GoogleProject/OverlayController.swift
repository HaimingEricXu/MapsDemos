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
import GooglePlaces
import GoogleMaps

class OverlayController {
    
    private var overlays = [GMSCircle]()
    private var lat: Double = 0.0
    private var long: Double = 0.0

    /// Heatmap buffering
    private lazy var activityView = UIActivityIndicatorView(style: .whiteLarge)
    
    func clear() {
        for x in overlays {
            x.map = nil
        }
    }
    
    func fetchData(completion: @escaping ([String : Any]?, Error?) -> Void) {
        #error("Register for API keys and enter them below; then, delete this line")
        let apiKey: String = "API KEY HERE"
        let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?&latlng=\(lat),\(long)&key=" + apiKey)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                if let array = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]{
                    completion(array, nil)
                }
            } catch {
                print(error)
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    func geocode(latitude: Double, longitude: Double, completion: @escaping (_ placemark: [CLPlacemark]?, _ error: Error?, _ pid: String) -> Void) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemark, error in
            guard let placemark = placemark, error == nil else {
                completion(nil, error, "")
                return
            }
            self.lat = latitude
            self.long = longitude
            var ans: String = ""
            self.fetchData { (dict, error) in
                let convert = String(describing: dict?["results"])
                var counter: Int = 0
                var characters = [Character]()
                let search = "place_id"
                for letter in search {
                    characters.append(letter)
                }
                var startPlaceId: Bool = false
                for ch in convert {
                    if (!startPlaceId) {
                        if (ch == characters[counter]) {
                            counter += 1
                        } else {
                            counter = 0
                            if (ch == "p") {
                                counter = 1
                            }
                        }
                        if (counter >= characters.count) {
                            startPlaceId = true
                        }
                    } else {
                        if (ch == ":") {
                            continue
                        } else if (ch == ";") {
                            break
                        } else {
                            ans += String(ch)
                        }
                    }
                }
                completion(placemark, nil, ans)
            }
            
        }
    }
    
    func showActivityIndicatory(view: UIView, darkMode: Bool) {
        activityView.center = view.center
        activityView.style = UIActivityIndicatorView.Style.large
        activityView.color = darkMode ? .white : .black
        view.addSubview(activityView)
        view.bringSubviewToFront(activityView)
        activityView.startAnimating()
    }
    
    func hideActivityIndicatory() {
        activityView.removeFromSuperview()
    }
    
    func drawCircle(mapView: GMSMapView, darkModeToggle: Bool, lat: Double, long: Double, rad: Double = 2000) {
        let circle = GMSCircle()
        circle.map = nil
        circle.position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        circle.radius = rad
        circle.fillColor = .clear
        circle.strokeColor = darkModeToggle ? .white : .black
        circle.strokeWidth = 3.4
        circle.map = mapView
        overlays.append(circle)
    }
}
