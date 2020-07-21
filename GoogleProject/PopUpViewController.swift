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
import MaterialComponents.MDCCard
import GoogleMaps

class PopUpViewController: UIViewController {

    private let imageController = LocationImageGenerator()
    private var pid: String = ""
    private var infoCard = MDCCard()
    private var dim: CGFloat = 300
    private var coord = CLLocationCoordinate2D()
    private var darkMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Setting the dimensions and offset
        let xOffset = view.frame.width / 7.5
        let yOffset = view.frame.height / 5
        let dim: CGFloat = 300
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        showAnimate()
        infoCard = MDCCard(frame: CGRect(x: xOffset, y: yOffset, width: dim, height: dim))
        let imageView = UIImageView()
        imageView.frame = CGRect(x: xOffset, y: yOffset, width: dim, height: dim * 2 / 3)
        imageController.viewImage(placeId: pid, localMarker: GMSMarker(), imageView: imageView, select: true)
        
        let infoText =  UITextView(frame: CGRect(x: xOffset, y: yOffset + imageView.frame.height, width: dim, height: dim / 6))
        infoText.text = "The current coordinates are (" + String(coord.latitude) + ", " + String(coord.longitude) + ")."
        infoText.textColor = darkMode ? .white : .black
        infoText.backgroundColor = darkMode ? .black : .white
        infoText.font = UIFont.systemFont(ofSize: 10)
        infoText.centerVertically()
        
        let backButton = UIButton(type: .custom)
        backButton.frame = CGRect(x: xOffset, y: yOffset + imageView.frame.height + infoText.frame.height, width: dim, height: dim / 6)
        backButton.layer.cornerRadius = 5
        backButton.layer.borderWidth = 1
        backButton.clipsToBounds = true
        backButton.backgroundColor = .systemTeal
        backButton.addTarget(self, action: #selector(removeAnimate), for: .touchUpInside)
        backButton.setTitle("Go Back", for: .normal)
        
        view.addSubview(infoCard)
        view.addSubview(imageView)
        view.sendSubviewToBack(infoCard)
        view.addSubview(backButton)
        view.bringSubviewToFront(backButton)
        view.addSubview(infoText)
    }
    
    private func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    func update(newCoord: CLLocationCoordinate2D, newPid: String, switchDarkMode: Bool) {
        coord = newCoord
        pid = newPid
        darkMode = switchDarkMode
    }
    
    @objc private func removeAnimate() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension UITextView {
    
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let horizontalOffset = (bounds.size.width - size.width * zoomScale) / 2
        let positiveHorizontalOffset = max(1, horizontalOffset)
        contentOffset.x = -positiveHorizontalOffset
        
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}
