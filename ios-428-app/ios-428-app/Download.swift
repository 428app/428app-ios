//
//  Download.swift
//  ios-428-app
//
//  Created by Leonard Loo on 11/12/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

// MARK: Alamofire

// Image cache which stores 100MB of data, and prefers 60MB of data
let imageCache = AutoPurgingImageCache(
    memoryCapacity: 100 * 1024 * 1024,
    preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
)

func downloadImage(imageUrlString: String, completed: @escaping (_ image: UIImage?) -> ()) -> Request? {
    // First cut off everything after ? in url string as there is no need to add such a long identifier
//    let imageUrlStr = imageUrlString.components(separatedBy: "?")[0]
    
    // Image exists in cache, so return image without starting an Alamofire request
    if let image = imageCache.image(withIdentifier: imageUrlString) {
        completed(image)
        return nil
    }
    return Alamofire.request(imageUrlString, method: .get, encoding: JSONEncoding.default).validate(contentType:
        ["image/*"]).responseImage { response in
            guard let image = response.result.value else {
                completed(nil)
                return
            }
            imageCache.add(image, withIdentifier: imageUrlString)
            completed(image)
            return
    }
}
