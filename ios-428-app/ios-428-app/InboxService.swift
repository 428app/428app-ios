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
        })
    }
    
    // Observes the names, photos and disciplines, of all your private chats used in InboxController
    func observeInboxes(completed: @escaping (_ isSuccess: Bool, _ inboxes: [Inbox]) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/inbox")
        
        ref.keepSynced(true)
        
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
        })
    }
    
    // Adds a private message to the private chat, used in ChatInboxController
    // It's a long function mainly because we have to decide whether to push this user a notification and update the badge count
    func addInboxChatMessage(inbox: Inbox, text: String, completed: @escaping (_ isSuccess: Bool, _ inbox: Inbox?) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false, nil)
            return
        }
        let poster = uid
        let inboxId: String = getInboxId(uid1: uid, uid2: inbox.uid)
        let timestamp = Date().timeIntervalSince1970
        let messagesRef: FIRDatabaseReference = REF_INBOX.child(inboxId).childByAutoId()
        let mid = messagesRef.key
        let newMessage: [String: Any] = ["message": text, "timestamp": timestamp, "poster": poster]
        
        // Creates new message in two places: Messages and Chats (lastMessage)
        // Do a multipath update to preserve atomicity, even for offline updates
        REF_BASE.updateChildValues(["inboxMessages/\(inboxId)/\(mid)": newMessage, "inboxs/\(inboxId)/mid": mid, "inboxs/\(inboxId)/lastMessage": text, "inboxs/\(inboxId)/timestamp": timestamp, "inboxs/\(inboxId)/poster": poster, "inboxs/\(inboxId)/hasNew:\(uid)": false]) { (err, ref) in
            if (err != nil) {
                completed(false, nil)
                return
            }
            
            // Populate front end with chat message - this is done before push notification logic because this has to be done fast!
            let msg = InboxMessage(mid: mid, text: text, inbox: inbox, date: Date(timeIntervalSince1970: timestamp), isSentByYou: true)
            inbox.addMessage(message: msg)
            completed(true, inbox)
            
            // Do push notification stuff here without a completion callback - Push notifications are not guaranteed to be delivered anyway
            
//            self.REF_INBOX.child(inboxId).observeSingleEvent(of: .value, with: { chatSnap in
//                if !chatSnap.exists() {
//                    return
//                }
//                guard let chatDict = chatSnap.value as? [String: Any], let hasNew = chatDict["hasNew:\(inbox.uid)"] as? Bool else {
//                    return
//                }
//                
//                // First check if the recipient has UserSettings - inboxMessages set to true AND user isLoggedIn. If not, don't bother queuing a push notification.
//                let settingsRef = self.REF_USERSETTINGS.child(inbox.uid)
//                
//                settingsRef.keepSynced(true) // Syncing settings is important
//                
//                settingsRef.observeSingleEvent(of: .value, with: { settingsSnap in
//                    // If the private messages setting exists, and is set to False, then terminate here
//                    if settingsSnap.exists() {
//                        // Check if /inboxMessages and /isLoggedIn are both true
//                        if let settingDict = settingsSnap.value as? [String: Bool], let acceptsInboxMessages = settingDict["inboxMessages"], let isLoggedIn = settingDict["isLoggedIn"] {
//                            if !acceptsInboxMessages || !isLoggedIn {
//                                // Not allowed to push messages. Increment badge count if necessary, then return
//                                if !hasNew {
//                                    self.adjustPushCount(isIncrement: true, uid: inbox.uid, completed: { (isSuccess) in })
//                                }
//                                self.REF_INBOX.child("\(inboxId)/hasNew:\(inbox.uid)").setValue(true)
//                                return
//                            }
//                        }
//                    }
//                    
//                    // Allowed to send push notifications
//                    
//                    if hasNew {
//                        // There are already new messages from this chat for this user, just send a notification without updating badge
//                        self.addToNotificationQueue(type: TokenType.INBOX, posterUid: uid, recipientUid: inbox.uid, cid: "", title: "Inbox", body: text)
//                        return
//                    }
//                    // No new messages for this user, set hasNew to true, and increment badge count for this user in Users table
//                    self.REF_INBOX.child("\(inboxId)/hasNew:\(inbox.uid)").setValue(true)
//                    self.adjustPushCount(isIncrement: true, uid: inbox.uid, completed: { (isSuccess) in
//                        // After badge count is incremented, then push notification. This is crucial because push notificatin reads off the badge count in the users table.
//                        self.addToNotificationQueue(type: TokenType.INBOX, posterUid: uid, recipientUid: inbox.uid, cid: "", title: "Inbox", body: text)
//                    })
//                })
//            })
        }
    }
    
    // Called whenever a user clicks on a private chat that is not previously seen to update the private chat's
    // message to seen. Also decrements badge count. Used in InboxController.
    func seeInboxMessages(inbox: Inbox, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let inboxId: String = getInboxId(uid1: uid, uid2: inbox.uid)
        
        // Get hasNew value, if it is not hasNew: false already then do not adjust badge count
        
        let ref = REF_INBOX.child("\(inboxId)/hasNew:\(uid)")
        ref.keepSynced(true)
        
        // Don't need a transaction here because the user is the only one updating this table for "seeing"
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists() {
                completed(false)
                return
            }
            guard let hasNew = snapshot.value as? Bool else {
                completed(false)
                return
            }
            if !hasNew {
                // There is already no hasNew for this user for this chat, so no need to decrement badge count
                completed(true)
                return
            }
            // Set hasNew to false and decrement badge count
            ref.setValue(false) { (err, ref) in
                if err != nil {
                    completed(false)
                    return
                }
                self.adjustPushCount(isIncrement: false, uid: uid, completed: { (isSuccess) in
                    completed(isSuccess)
                })
            }
        })
    }
    
}
