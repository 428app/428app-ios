//
//  Server.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/23/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage


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

// MARK: Alamofire

// Image cache which stores 100MB of data, and prefers 60MB of data
let imageCache = AutoPurgingImageCache(
    memoryCapacity: 100 * 1024 * 1024,
    preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
)


func downloadImage(imageUrlString: String, completed: @escaping (_ isSuccess: Bool, _ image: UIImage?) -> ()) -> Request? {
    if let image = imageCache.image(withIdentifier: imageUrlString) {
        log.info("here")
        completed(true, image)
        return nil
    }
    let request = Alamofire.request(imageUrlString, method: .get, encoding: JSONEncoding.default).validate(contentType: ["image/*"]).responseImage { response in
        log.info("\(response)")
        if response.result.isFailure {
            completed(false, nil)
            return
        }
        if let image = response.result.value {
            completed(true, image)
            imageCache.add(image, withIdentifier: imageUrlString)
            return
        }
        completed(false, nil)
    }
    return request
    
}
