//
//  PrivateChatService.swift
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

// Extends DataService to house Private Chat calls
extension NewDataService {
    
    // Returns chat id from two uids
    // The chat id is of the form <uid1>:<uid2>, with the lexicographically smaller uid being uid1
    open func getChatId(uid1: String, uid2: String) -> String {
        if uid1 < uid2 {
            return "\(uid1):\(uid2)"
        } else {
            return "\(uid2):\(uid1)"
        }
    }
    
    // Observes the names, photos and disciplines, of all your private chats used in PrivateChatController
    func observePrivateChats(completed: @escaping (_ isSuccess: Bool, _ privateChats: [PrivateChat]) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/privates")
        
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
            
            var chats: [PrivateChat] = []
            
            for snap in snaps {
                if let dict = snap.value as? [String: Any], let discipline = dict["discipline"] as? String, let name = dict["name"] as? String, let photo = dict["profilePhoto"] as? String {
                    let chat: PrivateChat = PrivateChat(uid: snap.key, name: name, profileImageName: photo, discipline: discipline)
                    chats.append(chat)
                }
            }
            completed(true, chats)
        })
        return (ref, handle)
    }
    
    // Observes the most recent message by one private chat, used in PrivateChatController
    func observeRecentChat(privateChat: PrivateChat, completed: @escaping (_ isSuccess: Bool, _ privateChat: PrivateChat?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let chatId: String = getChatId(uid1: uid, uid2: privateChat.uid)
        let ref: FIRDatabaseReference = REF_PRIVATECHATS.child(chatId)
        
        ref.keepSynced(true)
        
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                completed(false, nil)
                return
            }
            
            guard let dict = snapshot.value as? [String: Any], let mid = dict["mid"] as? String, let text = dict["lastMessage"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String, let dateMatched = dict["dateMatched"] as? String, let hasNewMessages = dict["hasNew:\(uid)"] as? Bool else {
                completed(false, nil)
                return
            }
            
            privateChat.dateMatched = dateMatched
            
            let date: Date = Date(timeIntervalSince1970: timestamp)
            let isSentByYou: Bool = poster == uid
            
            privateChat.hasNewMessages = hasNewMessages
            let msg = PrivateMessage(mid: mid, text: text, privateChat: privateChat, date: date, isSentByYou: isSentByYou)
            
            privateChat.clearMessages()
            privateChat.addMessage(message: msg)
            
            completed(true, privateChat)
        })
        return (ref, handle)
    }
    
    // Private helper function that takes in a snapshot of all private messages between two users and outputs a PrivateChat model
    fileprivate func processChatSnapshot(snapshot: FIRDataSnapshot, privateChat: PrivateChat, uid: String) -> PrivateChat? {
        if !snapshot.exists() {
            return nil
        }
        
        guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
            return nil
        }
        privateChat.clearMessages()
        for snap in snaps {
            if let dict = snap.value as? [String: Any], let text = dict["message"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String {
                let mid: String = snap.key
                let isSentByYou: Bool = poster == uid
                let date = Date(timeIntervalSince1970: timestamp)
                let msg = PrivateMessage(mid: mid, text: text, privateChat: privateChat, date: date, isSentByYou: isSentByYou)
                privateChat.addMessage(message: msg)
            }
        }
        return privateChat
    }
    
    // Observes all chat messags of one private chat, used in ChatController
    // Observes up till the limit, ordered by most recent timestamp
    func reobserveChatMessages(limit: UInt, privateChat: PrivateChat, completed: @escaping (_ isSuccess: Bool, _ privateChat: PrivateChat?) -> ()) -> (FIRDatabaseQuery, FIRDatabaseHandle) {
        
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let chatId: String = getChatId(uid1: uid, uid2: privateChat.uid)
        let ref: FIRDatabaseReference = REF_PRIVATEMESSAGES.child(chatId)
        ref.keepSynced(true)
        
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.keepSynced(true)
        let handle = q.observe(.value, with: { snapshot in
            let chat = self.processChatSnapshot(snapshot: snapshot, privateChat: privateChat, uid: uid)
            completed(chat != nil, chat)
        })
        return (q, handle)
    }
    
    // Observes all chat messags of one connection once, used when setting up ChatController
    // The only difference between this and reobserve is that this is a one time observer and does not return the handle
    func observeChatMessagesOnce(privateChat: PrivateChat, limit: UInt, completed: @escaping (_ isSuccess: Bool, _ privateChat: PrivateChat?) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let chatId: String = getChatId(uid1: uid, uid2: privateChat.uid)
        let ref: FIRDatabaseReference = REF_PRIVATEMESSAGES.child(chatId)
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.observeSingleEvent(of: .value, with: { snapshot in
            q.removeAllObservers()
            let chat = self.processChatSnapshot(snapshot: snapshot, privateChat: privateChat, uid: uid)
            completed(chat != nil, chat)
        })
    }
    
    // Adds a private message to the private chat, used in ChatController
    // It's a long function mainly because we have to decide whether to push this user a notification and update the badge count
    func addChatMessage(privateChat: PrivateChat, text: String, completed: @escaping (_ isSuccess: Bool, _ privateChat: PrivateChat?) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false, nil)
            return
        }
        let poster = uid
        let chatId: String = getChatId(uid1: uid, uid2: privateChat.uid)
        let timestamp = Date().timeIntervalSince1970
        let messagesRef: FIRDatabaseReference = REF_PRIVATEMESSAGES.child(chatId).childByAutoId()
        let mid = messagesRef.key
        let newMessage: [String: Any] = ["message": text, "timestamp": timestamp, "poster": poster]
        
        // Creates new message in two places: Messages and Chats (lastMessage)
        // Do a multipath update to preserve atomicity, even for offline updates
        REF_BASE.updateChildValues(["privateMessages/\(chatId)/\(mid)": newMessage, "privateChats/\(chatId)/mid": mid, "privateChats/\(chatId)/lastMessage": text, "privateChats/\(chatId)/timestamp": timestamp, "privateChats/\(chatId)/poster": poster, "privateChats/\(chatId)/hasNew:\(uid)": false]) { (err, ref) in
            if (err != nil) {
                completed(false, nil)
                return
            }
            
            // Populate front end with chat message - this is done before push notification logic because this has to be done fast!
            let msg = PrivateMessage(mid: mid, text: text, privateChat: privateChat, date: Date(timeIntervalSince1970: timestamp), isSentByYou: true)
            privateChat.addMessage(message: msg)
            completed(true, privateChat)
            
            // Do push notification stuff here without a completion callback - Push notifications are not guaranteed to be delivered anyway
            
            self.REF_PRIVATECHATS.child(chatId).observeSingleEvent(of: .value, with: { chatSnap in
                if !chatSnap.exists() {
                    return
                }
                guard let chatDict = chatSnap.value as? [String: Any], let hasNew = chatDict["hasNew:\(privateChat.uid)"] as? Bool else {
                    return
                }
                
                // First check if the recipient has UserSettings - privateMessages set to true AND user isLoggedIn. If not, don't bother queuing a push notification.
                let settingsRef = self.REF_USERSETTINGS.child(privateChat.uid)
                
                settingsRef.keepSynced(true) // Syncing settings is important
                
                settingsRef.observeSingleEvent(of: .value, with: { settingsSnap in
                    // If the private messages setting exists, and is set to False, then terminate here
                    if settingsSnap.exists() {
                        // Check if /privateMessages and /isLoggedIn are both true
                        if let settingDict = settingsSnap.value as? [String: Bool], let acceptsPrivateMessages = settingDict["privateMessages"], let isLoggedIn = settingDict["isLoggedIn"] {
                            if !acceptsPrivateMessages || !isLoggedIn {
                                // Not allowed to push messages. Increment badge count if necessary, then return
                                if !hasNew {
                                    self.adjustPushCount(isIncrement: true, uid: privateChat.uid, completed: { (isSuccess) in })
                                }
                                self.REF_PRIVATECHATS.child("\(chatId)/hasNew:\(privateChat.uid)").setValue(true)
                                return
                            }
                        }
                    }
                    
                    // Allowed to send push notifications
                    
                    if hasNew {
                        // There are already new messages from this chat for this user, just send a notification without updating badge
                        self.addToNotificationQueue(type: TokenType.PRIVATE, posterUid: uid, recipientUid: privateChat.uid, cid: "", title: "Private Message", body: text)
                        return
                    }
                    // No new messages for this user, set hasNew to true, and increment badge count for this user in Users table
                    self.REF_PRIVATECHATS.child("\(chatId)/hasNew:\(privateChat.uid)").setValue(true)
                    self.adjustPushCount(isIncrement: true, uid: privateChat.uid, completed: { (isSuccess) in
                        // After badge count is incremented, then push notification. This is crucial because push notificatin reads off the badge count in the users table.
                        self.addToNotificationQueue(type: TokenType.PRIVATE, posterUid: uid, recipientUid: privateChat.uid, cid: "", title: "Private Message", body: text)
                    })
                })
            })
        }
    }
    
    // Called whenever a user clicks on a private chat that is not previously seen to update the private chat's
    // message to seen. Also decrements badge count. Used in PrivateChatController.
    func seePrivateMessages(privateChat: PrivateChat, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let chatId: String = getChatId(uid1: uid, uid2: privateChat.uid)
        
        // Get hasNew value, if it is not hasNew: false already then do not adjust badge count
        
        let ref = REF_PRIVATECHATS.child("\(chatId)/hasNew:\(uid)")
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
