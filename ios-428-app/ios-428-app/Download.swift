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

fileprivate func requestImage(imageUrlString: String, completed: @escaping (_ image: UIImage?) -> ()) -> Request {
    return Alamofire.request(imageUrlString, method: .get, encoding: JSONEncoding.default).validate(contentType:
        ["image/*"]).responseImage { response in
            guard let image = response.result.value else { return }
            completed(image)
            imageCache.add(image, withIdentifier: imageUrlString)
    }
}

// This variant is used in dynamic loading scenarios, such as loading images within cells. In that case, we don't want to get the image back in a callback if it is in the cache, and we handle the cached case outside this function.
func downloadImageWithoutCache(imageUrlString: String, completed: @escaping (_ image: UIImage?) -> ()) -> Request {
    return requestImage(imageUrlString: imageUrlString, completed: completed)
}

func downloadImage(imageUrlString: String, completed: @escaping (_ image: UIImage?) -> ()) -> Request? {
    // Image exists in cache, so return image without starting an Alamofire request
    if let image = imageCache.image(withIdentifier: imageUrlString) {
        completed(image)
        return nil
    }
    return requestImage(imageUrlString: imageUrlString, completed: completed)
}
