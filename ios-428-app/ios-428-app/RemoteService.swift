//
//  RemoteService.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/24/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging
import FBSDKCoreKit
import FBSDKLoginKit

// Extends DataService to house Remote notification, and some utility calls
// Most of these calls are used by other services such as InboxService and ClassroomService
extension DataService {

    // Adds message to Queue that will be picked up by push server
    open func addToNotificationQueue(type: TokenType, posterUid: String, posterName: String, posterImage: String, recipientUid: String, pushToken: String, pushCount: Int, inApp: Bool, cid: String, title: String, body: String) {
        log.info("Adding to queue")
        // No need to async callback because notifications are not guaranteed anyway
        let dict: [String: Any] = ["type": type.rawValue, "posterUid": posterUid, "posterName": posterName, "posterImage": posterImage, "recipientUid": recipientUid, "pushToken": pushToken, "pushCount": pushCount, "inApp": inApp, "cid": cid, "title": title, "body": body]
        REF_QUEUE.childByAutoId().setValue(dict)
    }
    
    // Increments push count of user to display the right number for push notifications on the app's icon
    // Used by other services such as InboxService and ClassroomService
    open func adjustPushCount(isIncrement: Bool, uid: String, completed: @escaping (_ isSuccess: Bool) -> ()) {
        // Note: Transaction blocks only work when persistence is set to True
        self.REF_USERS.child(uid).runTransactionBlock({ (currentData) -> FIRTransactionResult in
            
            guard var user = currentData.value as? [String: Any] else {
                return FIRTransactionResult.abort()
            }
            if let currentPushCount = user["pushCount"] as? Int {
                user["pushCount"] = max(isIncrement ? currentPushCount + 1 : currentPushCount - 1, 0)
            } else {
                user["pushCount"] = isIncrement ? 1 : 0
            }
            currentData.value = user
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            completed(error == nil)
        }
    }
    
    // Used by update push count to set push count number for user
    fileprivate func setPushCount(uid: String, pushCount: Int, completed: @escaping (_ isSuccess: Bool) -> ()) {
        REF_USERS.child("\(uid)/pushCount").setValue(pushCount, withCompletionBlock: { (err, ref) in
            completed(err == nil)
        })
    }
    
    // Called in AppDelegate whenever a user leaves the app to go to the background to update push count (keeping the state consistent as a fail safe)
    func updatePushCount(completed: @escaping (_ isSuccess: Bool, _ pushCount: Int) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false, -1)
            return
        }
        
        // Note: This is potentially unscalable because we're updating the push count whenever a user minimizes the app
        
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { (userSnap) in
            var pushCount = 0
            
            guard let userDict = userSnap.value as? [String: Any] else {
                completed(true, pushCount)
                return
            }
            
            // Count all classrooms where hasUpdates is true
            if let classroomsDict = userDict["classrooms"] as? [String: [String: Any]] {
                for (_, v) in classroomsDict {
                    if let hasUpdates = v["hasUpdates"] as? Bool {
                        if hasUpdates {
                            pushCount += 1
                        }
                    }
                }
            }

            // Get all inboxes, and for each of them count all where hasNew is true
            guard let inboxDict = userDict["inbox"] as? [String: [String: Any]] else {
                // No inboxes
                self.setPushCount(uid: uid, pushCount: pushCount, completed: { (isSuccess) in
                    completed(isSuccess, pushCount)
                })
                return
            }
            
            var numberOfInboxesLeft = inboxDict.count
            for (k, _) in inboxDict {
                let inboxId = self.getInboxId(uid1: uid, uid2: k)
                let ref = self.REF_INBOX.child("\(inboxId)/hasNew:\(uid)")
                ref.keepSynced(true)
                ref.observeSingleEvent(of: .value, with: { (chatSnap) in
                    if let hasNew = chatSnap.value as? Bool {
                        if hasNew {
                            pushCount += 1
                        }
                    }
                    numberOfInboxesLeft -= 1
                    if numberOfInboxesLeft == 0 {
                        self.setPushCount(uid: uid, pushCount: pushCount, completed: { (isSuccess) in
                            completed(isSuccess, pushCount)
                        })
                    }
                })
            }
        })
    }
}
