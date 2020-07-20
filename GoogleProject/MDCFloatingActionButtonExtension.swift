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

import SwiftUI
import MaterialComponents.MaterialButtons

extension MDCFloatingButton {
    
    public func auto(view: UIView, xcoord: Double, ycoord: Double) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: CGFloat(xcoord / 2)).isActive = true
        self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: CGFloat(ycoord / 2)).isActive = true
        self.widthAnchor.constraint(equalToConstant: 48).isActive = true
        self.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
}
