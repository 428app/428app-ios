//
//  Upload.swift
//  ios-428-app
//
//  Created by Leonard Loo on 11/12/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

// MARK: File path storage

// Store profile photo or cover photo temporarily in case user closes app while uploading picture to Firebase storage
func cachePhotoToUpload(data: Data?, isProfilePic: Bool = true) {
    let fileManager = FileManager.default
    let picPath = isProfilePic ? "profile_photo.jpg" : "cover_photo.jpg"
    let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(picPath)
    if data == nil {
        // Delete stored data
        do {
            try fileManager.removeItem(atPath: paths as String)
        } catch {
            log.info("Failed to remove profile_photo after upload is complete")
        }
    } else {
        // Store data
        fileManager.createFile(atPath: paths as String, contents: data, attributes: nil)
    }
}

func getPhotoToUpload(isProfilePic: Bool = true) -> UIImage? {
    let picPath = isProfilePic ? "profile_photo.jpg" : "cover_photo.jpg"
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0] as NSString
    let fileManager = FileManager.default
    let imagePath = documentsDirectory.appendingPathComponent(picPath)
    if fileManager.fileExists(atPath: imagePath){
        return UIImage(contentsOfFile: imagePath)
    }
    return nil
}
