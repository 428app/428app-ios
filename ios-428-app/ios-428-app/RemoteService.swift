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
        // Look for all this user's private chats, look at all the Chats and see how many hasNew, then update pushCount, and return
        // TODO: This will have to also look at Classrooms once those are up
        REF_USERS.child("\(uid)/inbox").observeSingleEvent(of: .value, with: { privatesSnap in
            if !privatesSnap.exists() {
                completed(true, 0)
                return
            }
            guard let privSnaps = privatesSnap.children.allObjects as? [FIRDataSnapshot] else {
                completed(true, 0)
                return
            }
            var privatesNum = privSnaps.count
            var pushCount = 0
            for privSnap in privSnaps {
                let uid2 = privSnap.key
                let inboxId = self.getInboxId(uid1: uid, uid2: uid2)
                let ref = self.REF_INBOX.child("\(inboxId)/hasNew:\(uid)")
                ref.keepSynced(true)
                ref.observeSingleEvent(of: .value, with: { chatSnap in
                    if chatSnap.exists() {
                        if let hasNew = chatSnap.value as? Bool {
                            if hasNew {
                                pushCount += 1
                            }
                        }
                    }
                    privatesNum -= 1
                    if privatesNum == 0 { // Done with looking at all private chats
                        // Update push count in user table and return the updated push count
                        self.setPushCount(uid: uid, pushCount: pushCount, completed: { (isSuccess) in
                            completed(isSuccess, pushCount)
                        })
                    }
                })
            }
        })
    }

}
