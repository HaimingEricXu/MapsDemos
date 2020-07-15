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
    
    @IBOutlet private weak var backButton: UIButton!
    private var coord = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showMap()
    }
    
    private func showMap() {
        let panoView = GMSPanoramaView.panorama(withFrame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), nearCoordinate: coord)
        self.view.addSubview(panoView)
        panoView.moveNearCoordinate(coord)
        self.view.bringSubviewToFront(backButton)
    }
    
    func setValues(newCoord: CLLocationCoordinate2D) {
        coord = newCoord
    }
    
    @IBAction private func menu(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
