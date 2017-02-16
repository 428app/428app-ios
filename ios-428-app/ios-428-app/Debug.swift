//
//  Debug.swift
//  ios-428-app
//
//  Created by Leonard Loo on 2/15/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

// Print statements for off-app
let DEFAULTS_DEBUG = UserDefaults.standard

let KEY_DEBUG = "debug"
func writeToDebug(line: String?) {
    if line == nil {
        DEFAULTS_DEBUG.removeObject(forKey: KEY_DEBUG)
    } else {
        let currentLines = getDebug() == nil ? "" : getDebug()!
        DEFAULTS_DEBUG.set(currentLines + "\n====================\n" + line!, forKey: KEY_DEBUG)
    }
    DEFAULTS_DEBUG.synchronize()
}
func getDebug() -> String? {
    if let lines = DEFAULTS_DEBUG.object(forKey: KEY_DEBUG) as? String {
        return lines
    }
    return nil
}
