//
//  Server.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/23/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

// MARK: UserDefaults

// Stored uid that is used by almost all DataService functions
let DEFAULTS = UserDefaults.standard
let KEY_UID = "uid"
func getStoredUid() -> String? {
    if let storedUid = DEFAULTS.object(forKey: KEY_UID) as? String {
        return storedUid
    }
    return nil
}
func saveUid(uid: String) {
    DEFAULTS.set(uid, forKey: KEY_UID)
    DEFAULTS.synchronize()
}

// Stored true if user still has yet to fill in profile in intro
// Used this to safeguard against users who login, not fill in intro, and close the app
let KEY_HASTOFILL = "hasToFill"
func hasToFill() -> Bool {
    return DEFAULTS.object(forKey: KEY_HASTOFILL) != nil
}
func setHasToFillInfo(hasToFill: Bool) {
    if hasToFill {
        DEFAULTS.set("true", forKey: KEY_HASTOFILL)
    } else {
        DEFAULTS.removeObject(forKey: KEY_HASTOFILL)
    }
    DEFAULTS.synchronize()
}
