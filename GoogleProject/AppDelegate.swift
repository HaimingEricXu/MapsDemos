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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
<<<<<<< HEAD
        GMSServices.provideAPIKey(apikeys.mapsAPI)
        GMSPlacesClient.provideAPIKey(apikeys.placesAPI)
||||||| b0312e7
        #error("Register for API keys and enter them below; then, delete this line")
        GMSServices.provideAPIKey("API KEY HERE")
        GMSPlacesClient.provideAPIKey("API KEY HERE")
=======
        // TODO: Add your API keys
        #error("Register for API keys and enter them below; then, delete this line")
        GMSServices.provideAPIKey("API KEY HERE")
        GMSPlacesClient.provideAPIKey("API KEY HERE")
>>>>>>> 73ae79118319b0b39f135bfb209605fe1b07d53d
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
