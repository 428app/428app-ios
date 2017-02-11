//
//  Functions.swift
//  ios-428-app
//
//  Common functions used in multiple classes
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import XCGLogger
import SwiftSpinner
import CoreLocation

let log = XCGLogger.default

// Custom Segue: NOT BEING USED
func presentTopToDown(src: UIViewController, dst: UIViewController) {
    src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
    dst.view.transform = CGAffineTransform(translationX: 0, y: -src.view.frame.size.height)
    
    UIView.animate(withDuration: 0.35, animations: {
        dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
    }) { (completed) in
        src.present(dst, animated: false, completion: nil)
    }
}

// Used in SettingsController and SettingCell to countdown time till 4:28pm
var timerForCountdown = Timer()

func showErrorAlert(vc: UIViewController, title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.view.tintColor = GREEN_UICOLOR
    let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
    alertController.addAction(okAction)
    vc.present(alertController, animated: true, completion: {
        alertController.view.tintColor = GREEN_UICOLOR
    })
}

// SwiftSpinner loader
func showLoader(message: String) {
    SwiftSpinner.setTitleFont(FONT_MEDIUM_XLARGE)
    SwiftSpinner.show(message)
}

func hideLoader() {
    SwiftSpinner.hide()
}

// Converts age birthday MM/DD/YYYY string to age: Returns -1 if invalid Sting
func convertBirthdayToAge(birthday: String) -> Int {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy"
    if let birthDate = dateFormatter.date(from: birthday),
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year {
        return age
    }
    return -1
}

// Converts <lat>, <lon> String to <Country>, <City> String
func convertLocationToCityAndCountry(location: String, completed: @escaping (_ cityCountry: String) -> ()) {
    let latlon = location.components(separatedBy: ",")
    let errorLocation: String = "Unknown"
    if latlon.count != 2 {
        completed(errorLocation)
        return
    }
    guard let lat = Double(latlon[0].trim()), let lon = Double(latlon[1].trim()) else {
        completed(errorLocation)
        return
    }
    let geocoder = CLGeocoder()
    let loc = CLLocation(latitude: lat, longitude: lon)
    
    geocoder.reverseGeocodeLocation(loc) { (placemarks, error) in
        if error != nil || placemarks == nil || placemarks!.count == 0 {
            completed(errorLocation)
            return
        }
        let place: CLPlacemark = placemarks![0]
        guard let address = place.addressDictionary else {
            completed(errorLocation)
            return
        }
        // Outputs <City>, <State>, <Country> provided city =/= state =/= country
        var cityCountry = ""
        var city = ""
        var state = ""
        var country = ""
        if let c = address["City"] as? String {
            city = c
        }
        if let s = address["State"] as? String {
            state = s
        }
        if let c = address["Country"] as? String {
           country = c
        }
        cityCountry = city
        if city != state {
            cityCountry += ", \(state)"
        }
        if city != country && state != country {
            cityCountry += ", \(country)"
        }
        completed(cityCountry)
        return
    }
}
