//
//  InboxService.swift
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

// Extends DataService to house Inbox calls
extension DataService {
    
    // Returns inbox id from two uids
    // The inbox id is of the form <uid1>:<uid2>, with the lexicographically smaller uid being uid1
    open func getInboxId(uid1: String, uid2: String) -> String {
        if uid1 < uid2 {
            return "\(uid1):\(uid2)"
        } else {
            return "\(uid2):\(uid1)"
        }
    }
    
    // MARK: Inbox
    
    // Used to get inbox from a user's ProfileController to link to chat
    func getInbox(profile2: Profile, completed: @escaping (_ isSuccess: Bool, _ inbox: Inbox) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let uid2 = profile2.uid
        let inboxId = getInboxId(uid1: uid, uid2: uid2)
        REF_INBOX.child(inboxId).observeSingleEvent(of: .value, with: { snapshot in
            let inbox = Inbox(uid: uid2, name: profile2.name, profileImageName: profile2.profileImageName, discipline: profile2.discipline, hasNewMessages: false)
            guard let inboxDict = snapshot.value as? [String: Any] else {
                // Inbox does not exist with this user yet, new message!
                completed(true, inbox)
                return
            }
            // Check if there are new messages for this user
            var hasNewMessages = false
            if let hasNewMessages_ = inboxDict["hasNew:\(uid)"] as? Bool {
                hasNewMessages = hasNewMessages_
            }
            inbox.hasNewMessages = hasNewMessages
            completed(true, inbox)
            return
        })
    }
    
    // Observes the names, photos and disciplines, of all your private chats used in InboxController
    func observeInboxes(completed: @escaping (_ isSuccess: Bool, _ inboxes: [Inbox]) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/inbox")
        
        // Observed on value as not childAdded, as profile pic can change
        let handle = ref.observe(.value, with: { snapshot in
            
            if !snapshot.exists() {
                completed(false, [])
                return
            }
            guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
                completed(false, [])
                return
            }
            
            var chats: [Inbox] = []
            
            for snap in snaps {
                if let dict = snap.value as? [String: Any], let discipline = dict["discipline"] as? String, let name = dict["name"] as? String, let photo = dict["profilePhoto"] as? String {
                    let chat: Inbox = Inbox(uid: snap.key, name: name, profileImageName: photo, discipline: discipline)
                    chats.append(chat)
                }
            }
            completed(true, chats)
            return
        })
        return (ref, handle)
    }
    
    // Observes the most recent message by one inbox chat, used in InboxController
    func observeRecentInbox(inbox: Inbox, completed: @escaping (_ isSuccess: Bool, _ inbox: Inbox?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let inboxId: String = getInboxId(uid1: uid, uid2: inbox.uid)
        
        let ref: FIRDatabaseReference = REF_INBOX.child(inboxId)
        
        ref.keepSynced(true)
        
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                
                completed(false, nil)
                return
            }
            
            guard let dict = snapshot.value as? [String: Any], let mid = dict["mid"] as? String, let text = dict["lastMessage"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String, let hasNewMessages = dict["hasNew:\(uid)"] as? Bool else {
                completed(false, nil)
                return
            }
            
            let date: Date = Date(timeIntervalSince1970: timestamp)
            let isSentByYou: Bool = poster == uid
            
            inbox.hasNewMessages = hasNewMessages
            let msg = InboxMessage(mid: mid, text: text, inbox: inbox, date: date, isSentByYou: isSentByYou)
            
            inbox.clearMessages()
            inbox.addMessage(message: msg)
            
            completed(true, inbox)
            return
        })
        return (ref, handle)
    }
    
    // MARK: Chats
    
    // Private helper function that takes in a snapshot of all private messages between two users and outputs a Inbox model
    fileprivate func processChatSnapshot(snapshot: FIRDataSnapshot, inbox: Inbox, uid: String) -> Inbox? {
        if !snapshot.exists() {
            return nil
        }
        
        guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
            return nil
        }
        inbox.clearMessages()
        for snap in snaps {
            if let dict = snap.value as? [String: Any], let text = dict["message"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String {
                let mid: String = snap.key
                let isSentByYou: Bool = poster == uid
                let date = Date(timeIntervalSince1970: timestamp)
                let msg = InboxMessage(mid: mid, text: text, inbox: inbox, date: date, isSentByYou: isSentByYou)
                inbox.addMessage(message: msg)
            }
        }
        return inbox
    }
    
    // Observes all chat messags of one private chat, used in ChatInboxController
    // Observes up till the limit, ordered by most recent timestamp
    func reobserveInboxChatMessages(limit: UInt, inbox: Inbox, completed: @escaping (_ isSuccess: Bool, _ inbox: Inbox?) -> ()) -> (FIRDatabaseQuery, FIRDatabaseHandle) {
        
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let inboxId: String = getInboxId(uid1: uid, uid2: inbox.uid)
        let ref: FIRDatabaseReference = REF_INBOXMESSAGES.child(inboxId)
        ref.keepSynced(true)
        
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.keepSynced(true)
        let handle = q.observe(.value, with: { snapshot in
            let chat = self.processChatSnapshot(snapshot: snapshot, inbox: inbox, uid: uid)
            completed(chat != nil, chat)
            return
        })
        return (q, handle)
    }
    
    // Observes all chat messags of one connection once, used when setting up ChatInboxController
    // The only difference between this and reobserve is that this is a one time observer and does not return the handle
    func observeInboxChatMessagesOnce(inbox: Inbox, limit: UInt, completed: @escaping (_ isSuccess: Bool, _ inbox: Inbox?) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let inboxId: String = getInboxId(uid1: uid, uid2: inbox.uid)
        let ref: FIRDatabaseReference = REF_INBOXMESSAGES.child(inboxId)
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.observeSingleEvent(of: .value, with: { snapshot in
            q.removeAllObservers()
            let chat = self.processChatSnapshot(snapshot: snapshot, inbox: inbox, uid: uid)
            completed(chat != nil, chat)
            return
        })
    }
    
    // Private helper function used by addInboxChatMessage to update both sides' users' inbox details only if it is a new chat
    fileprivate func initUsersInbox(uid1: String, uid2: String, discipline1: String, name1: String, profilePhoto1: String, discipline2: String, name2: String, profilePhoto2: String) {
        self.REF_USERS.child("\(uid1)/inbox/\(uid2)").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                return
            }
            // New chat, so initialize inboxes of both sides
            let uidValues: [String: Any] = ["discipline": discipline2, "name": name2, "profilePhoto": profilePhoto2]
            self.REF_USERS.child("\(uid1)/inbox/\(uid2)").updateChildValues(uidValues)
            let uid2Values: [String: Any] = ["discipline": discipline1, "name": name1, "profilePhoto": profilePhoto1]
            self.REF_USERS.child("\(uid2)/inbox/\(uid1)").updateChildValues(uid2Values)
        })
    }
    
    // Adds a private message to the private chat, used in ChatInboxController
    // It's a long function mainly because we have to decide whether to push this user a notification and update the push count
    func addInboxChatMessage(inbox: Inbox, text: String, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid(), let profile = myProfile else {
            completed(false)
            return
        }
        let poster = uid
        let uid2 = inbox.uid
        let inboxId: String = getInboxId(uid1: uid, uid2: uid2)
        let timestamp = Date().timeIntervalSince1970
        
        // Append message to inbox messages first and send complete
        let messagesRef: FIRDatabaseReference = REF_INBOXMESSAGES.child(inboxId).childByAutoId()
        let mid = messagesRef.key
        let newMessage: [String: Any] = ["message": text, "timestamp": timestamp, "poster": poster]
        messagesRef.setValue(newMessage) { (err, ref) in
            completed(err == nil)
            // NOTE: We do not return here because there is also no more completes down below this function
        }
        
        // Need to get hasNew of recipient user first
        self.REF_INBOX.child("\(inboxId)/hasNew:\(uid2)").observeSingleEvent(of: .value, with: { hasNewSnap in
            var hasNew = false
            if let hasNew_ = hasNewSnap.value as? Bool {
                hasNew = hasNew_
            }

            // Set joint inbox
            let inboxValues: [String: Any] = ["hasNew:\(uid)": false, "hasNew:\(uid2)": true, "lastMessage": text, "mid": mid, "poster": poster, "timestamp": timestamp]
            self.REF_INBOX.child(inboxId).updateChildValues(inboxValues)
            
            // Set each other's inbox if there were no inbox
            self.initUsersInbox(uid1: uid, uid2: uid2, discipline1: profile.discipline, name1: profile.name, profilePhoto1: profile.profileImageName, discipline2: inbox.discipline, name2: inbox.name, profilePhoto2: inbox.profileImageName)

            // Decide if push notification should be sent
            
            // Grab recipient user settings first
            let settingsRef = self.REF_USERSETTINGS.child(uid2)
            settingsRef.keepSynced(true)
            settingsRef.observeSingleEvent(of: .value, with: { settingsSnap in
                var inAppSettings = true
                if let settingDict = settingsSnap.value as? [String: Bool], let inApp = settingDict["inAppNotifications"] {
                    inAppSettings = inApp
                }
                // Check if /inboxMessages and /isLoggedIn are both true
                if let settingDict = settingsSnap.value as? [String: Bool], let acceptsInboxMessages = settingDict["inboxMessages"], let isLoggedIn = settingDict["isLoggedIn"] {
                    if !acceptsInboxMessages || !isLoggedIn {
                        // Not allowed to push messages. Increment push count if necessary, then return
                        if !hasNew {
                            self.adjustPushCount(isIncrement: true, uid: uid2, completed: { (isSuccess) in })
                        }
                        return
                    }
                }
                
                // Allowed to push notification, grab push token and push count, then add to notification queue
                self.REF_USERS.child(uid2).observeSingleEvent(of: .value, with: { userSnap in
                    guard let userDict = userSnap.value as? [String: Any], let pushToken = userDict["pushToken"] as? String, let pushCount = userDict["pushCount"] as? Int else {
                        return
                    }
                    if hasNew {
                        // There are already new push notifications for this user, just send notification without incrementing push count
                        self.addToNotificationQueue(type: .INBOX, posterUid: uid, posterName: profile.name, posterImage: profile.profileImageName, recipientUid: uid2, pushToken: pushToken, pushCount: pushCount, inApp: inAppSettings, cid: "", title: "Private Message", body: text)
                    } else {
                        self.adjustPushCount(isIncrement: true, uid: uid2, completed: { (isSuccessAdjusted) in
                            if isSuccessAdjusted {
                                self.addToNotificationQueue(type: .INBOX, posterUid: uid, posterName: profile.name, posterImage: profile.profileImageName, recipientUid: uid2, pushToken: pushToken, pushCount: pushCount + 1, inApp: inAppSettings, cid: "", title: "Private Message", body: text)
                            }
                        })
                    }
                })
            })
        })
    }
    
    // Called whenever a user clicks on a private chat that is not previously seen to update the private chat's
    // message to seen. Also decrements push count. Used in InboxController.
    func seeInboxMessages(inbox: Inbox, completed: @escaping (_ isSuccess: Bool) -> ()) {
        log.info("Seeing inbox messages")
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        
        let inboxId: String = getInboxId(uid1: uid, uid2: inbox.uid)
        REF_INBOX.child("\(inboxId)/hasNew:\(uid)").setValue(false) { (err, ref) in
            self.updatePushCount { (isSuccess, pushCount) in }
        }
    }
    
}
