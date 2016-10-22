//
//  Functions.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import XCGLogger

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

// TODO: Add in the full list of disciplines here
let DISCIPLINE_OPTIONS = ["Business", "Computer Science", "Biology", "East Asian Studies", "Physics", "Electrical Engineering"]
let DISCIPLINE_ICONS = ["business", "computer", "biology", "eastasian", "physics", "electricengineering"]
