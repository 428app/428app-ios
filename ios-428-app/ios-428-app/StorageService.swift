//
//  Storage.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/26/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class StorageService {
    
    static let ss = StorageService()
    
    fileprivate var _REF_BASE = FIRStorage.storage().reference().child("\(DB_ROOT)")
    fileprivate var _REF_USER = FIRStorage.storage().reference().child("\(DB_ROOT)/user")
    
    var REF_BASE: FIRStorageReference {
        get {
            return _REF_BASE
        }
    }
    
    var REF_USER: FIRStorageReference {
        get {
            return _REF_USER
        }
    }
    
    // Upload profile pic to cloud storage, used in EditProfileController
    func uploadOwnPic(data: Data, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        // If it is not profile pic, it is cover pic
        let filePath = "profile_photo"
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        REF_USER.child("\(uid)/\(filePath)").put(data, metadata: metadata) { (metadata, error) in
            if error != nil || metadata == nil {
                log.error("[Error] Fail to store image in cloud storage")
                completed(false)
                return
            } else {
                 if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    log.info("url of uploaded: \(imageUrl)")
                    
                    DataService.ds.updateUserPhoto(profilePhotoUrl: imageUrl, completed: { (isSuccess) in
                        if !isSuccess {
                            completed(false)
                            return
                        }
                        DataService.ds.updateCachedDetailsInInboxes(profilePhoto: imageUrl, completed: { (isCachedSuccess) in
                            if !isCachedSuccess {
                                log.error("[Error] Failed to update cached details in all connections")
                            }
                            completed(isCachedSuccess)
                            return
                        })
                    })
                    
                 } else {
                    completed(false)
                    log.error("[Error] Fail to retrieve image url from cloud storage")
                    return
                }
            }
        }
    }
    
}

