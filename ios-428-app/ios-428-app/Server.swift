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

let photoCache = AutoPurgingImageCache(
    memoryCapacity: 100 * 1024 * 1024,
    preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
)

func downloadImage(imageUrlString: String, completed: @escaping (_ isSuccess: Bool, _ image: UIImage?) -> ()) {
//    guard let url = NSURL(string: imageUrlString) else {
//        completed(false, nil)
//        return
//    }
    Alamofire.request(imageUrlString, method: .get, encoding: JSONEncoding.default).validate(contentType: ["image/*"]).responseImage { response in
        log.info("\(response)")
        if response.result.isFailure {
            completed(false, nil)
            return
        }
        if let image = response.result.value {
            completed(true, image)
            return
        }
        completed(false, nil)
    }
    
    
//    Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).validate(contentType: ["image/*"]).responseImage() {
    
}
//    Alamofire.request(.GET, imageUrlString).validate(contentType: ["image/*"]).responseImage() {
    


//if let image = self.imageCache.objectForKey(imageURL) as? UIImage {
//    cell.imageView.image = image
//} else {
//    // 3
//    cell.imageView.image = nil
//    
//    // 4
//    cell.request = Alamofire.request(.GET, imageURL).validate(contentType: ["image/*"]).responseImage() {
//        (request, _, image, error) in
//        if error == nil && image != nil {
//            // 5
//            self.imageCache.setObject(image!, forKey: request.URLString)
//            
//            // 6
//            if request.URLString == cell.request?.request.URLString {
//                cell.imageView.image = image
//            }
//        } else {
//            /*
//             If the cell went off-screen before the image was downloaded, we cancel it and
//             an NSURLErrorDomain (-999: cancelled) is returned. This is a normal behavior.
//             */
//        }
//    }
//}
