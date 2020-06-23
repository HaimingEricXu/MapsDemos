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

class StreetViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    var lat: Double!
    var long: Double!
    var dark: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = dark ? .black : .white
        showMap()
    }
    
    func showMap() {
        let panoView = GMSPanoramaView.panorama(withFrame: CGRect(x: 0, y: 74, width: 414, height: 825), nearCoordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
        self.view.addSubview(panoView)
        panoView.moveNearCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: long))
        self.view.bringSubviewToFront(backButton)
    }
    
    @IBAction func menu(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
