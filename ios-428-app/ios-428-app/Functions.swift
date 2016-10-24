//
//  Functions.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import XCGLogger
import SwiftSpinner

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
    vc.present(alertController, animated: true, completion: nil)
}

// SwiftSpinner loader
func showLoader(message: String) {
    SwiftSpinner.setTitleFont(FONT_MEDIUM_XLARGE)
    SwiftSpinner.show(message)
}

func hideLoader() {
    SwiftSpinner.hide()
}
