//
//  UserDefaults.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/23/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

let DEFAULTS = UserDefaults.standard

// Store user push token
let KEY_TOKEN = "pushtoken"
func getPushToken() -> String? {
    if let storedToken = DEFAULTS.object(forKey: KEY_TOKEN) as? String {
        return storedToken
    }
    return nil
}
func savePushToken(token: String?) {
    if token == nil {
        DEFAULTS.removeObject(forKey: KEY_TOKEN)
    } else {
        DEFAULTS.set(token!, forKey: KEY_TOKEN)
    }
    DEFAULTS.synchronize()
}

// Stored uid that is used by almost all DataService functions
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

let KEY_DISCIPLINE = "discipline"
func getStoredDiscipline() -> String? {
    if let storedDiscipline = DEFAULTS.object(forKey: KEY_DISCIPLINE) as? String {
        return storedDiscipline
    }
    return nil
}
func saveDiscipline(discipline: String) {
    DEFAULTS.set(discipline, forKey: KEY_DISCIPLINE)
    DEFAULTS.synchronize()
}

let KEY_NAME = "name"
func getStoredName() -> String? {
    if let storedName = DEFAULTS.object(forKey: KEY_NAME) as? String {
        return storedName
    }
    return nil
}
func saveName(name: String) {
    DEFAULTS.set(name, forKey: KEY_NAME)
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

