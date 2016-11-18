//
//  DataService.swift
//  ios-428-app
//
//  DataService powered by Firebase
//  Created by Leonard Loo on 10/23/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

class DataService {
    
    static let ds = DataService()
    fileprivate var _REF_BASE = FIRDatabase.database().reference()
    fileprivate var _REF_USERS = FIRDatabase.database().reference().child("/users")
    fileprivate var _REF_CHATS = FIRDatabase.database().reference().child("/chats")
    fileprivate var _REF_MESSAGES = FIRDatabase.database().reference().child("/messages")
    fileprivate var _REF_QUEUE = FIRDatabase.database().reference().child("/queue/tasks") // Queue for notifications to be sent out
    
    var REF_BASE: FIRDatabaseReference {
        get {
            return _REF_BASE
        }
    }
    
    var REF_USERS: FIRDatabaseReference {
        get {
            return _REF_USERS
        }
    }
    
    var REF_CHATS: FIRDatabaseReference {
        get {
            return _REF_CHATS
        }
    }
    
    var REF_MESSAGES: FIRDatabaseReference {
        get {
            return _REF_MESSAGES
        }
    }
    
    var REF_QUEUE: FIRDatabaseReference {
        get {
            return _REF_QUEUE
        }
    }
    
    // To be called whenever user logs out
    func removeAllObservers() {
        _REF_BASE.removeAllObservers()
        _REF_USERS.removeAllObservers()
        _REF_CHATS.removeAllObservers()
        _REF_MESSAGES.removeAllObservers()
        _REF_QUEUE.removeAllObservers()
    }
    
    // MARK: User
    
    func logout(completed: (_ isSuccess: Bool) -> ()) {
        if let auth = FIRAuth.auth(), let _ = try? auth.signOut() {
            self.removeAllObservers()
            FBSDKLoginManager().logOut()
            completed(true)
            return
        }
        completed(false)
    }
    
    // Called in LoginController to create new user or log existing user in
    func loginFirebaseUser(authuid: String, name: String, birthday: String, pictureUrl: String, timezone: Double, completed: @escaping (_ isSuccess: Bool, _ isFirstTimeUser: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false, true)
            return
        }
        
        // Update name locally
        saveName(name: name)
        
        let timeNow = Date().timeIntervalSince1970
        let user: [String: Any] = ["authuid": authuid, "name": name, "birthday": birthday, "profilePhoto": pictureUrl, "timezone": timezone, "lastSeen": timeNow]
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                // Check if user has already filled in at least org, school and discipline, if not label first time user
                var isFirstTimeUser = true
                if let userDict = snapshot.value as? [String: Any], let _ = userDict["organization"] as? String, let _ = userDict["school"] as? String, let _ = userDict["discipline"] as? String {
                    isFirstTimeUser = false
                }
                // Update user info
                self.REF_USERS.child(uid).updateChildValues(user, withCompletionBlock: { (err, ref) in
                    completed(err == nil, isFirstTimeUser)
                })
            } else {
                // Create new user
                self.REF_USERS.child(uid).setValue(user, withCompletionBlock: { (error, ref) in
                    completed(error == nil, true)
                })
            }
        })
    }
    
    // Called in LoginController to update own location, after location manager gets it
    func updateUserLocation(lat: Double, lon: Double, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let timeNow = Date().timeIntervalSince1970
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USERS.child(uid).updateChildValues(["location": "\(lat),\(lon)", "lastSeen": timeNow], withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error.
                completed(false)
            }
        })
    }
    
    // Updates the user push token: Used in two places - one in LoginController and one in AppDelegate
    func updateUserPushToken() {
        guard let uid = getStoredUid(), let token = getPushToken() else {
            return
        }
        // set savePushToken(nil) here
        REF_USERS.child("\(uid)/pushToken").setValue(token, withCompletionBlock: { (err, ref) in
            if err == nil {
                // No need to save push token anymore
                savePushToken(token: nil)
            }
        })
    }
    
    // Updates own last seen in AppDelegate's applicationDidBecomeActive
    func updateUserLastSeen(completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let timeNow = Date().timeIntervalSince1970
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USERS.child(uid).updateChildValues(["lastSeen": timeNow], withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error
                completed(false)
            }
        })
    }
    
    // Update own profile data; Called in IntroController and SettingControllers
    func updateUserFields(organization: String? = nil, school: String? = nil, discipline: String? = nil, tagline1: String? = nil, tagline2: String? = nil, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        var userFields: [String: Any] = [:]
        if organization != nil {
            userFields["organization"] = organization!
        }
        if school != nil {
            userFields["school"] = school!
        }
        if discipline != nil {
            userFields["discipline"] = discipline!
        }
        if tagline1 != nil {
            userFields["tagline1"] = tagline1!.lowercaseFirstLetter()
        }
        if tagline2 != nil {
            userFields["tagline2"] = tagline2!.lowercaseFirstLetter()
        }
        
        // Update discipline locally
        if discipline != nil {
            saveDiscipline(discipline: discipline!)
        }
        
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USERS.child(uid).updateChildValues(userFields, withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error
                completed(false)
            }
        })
    }
    
    // Similar to updateUserFields, but only used by StorageService
    func updateUserPhotos(profilePhotoUrl: String? = nil, coverPhotoUrl: String? = nil, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        var userPhotos: [String: Any] = [:]
        if profilePhotoUrl != nil {
            userPhotos["profilePhoto"] = profilePhotoUrl!
        }
        if coverPhotoUrl != nil {
            userPhotos["coverPhoto"] = coverPhotoUrl!
        }
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USERS.child(uid).updateChildValues(userPhotos, withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error
                completed(false)
            }
        })
    }
    
    // Retrive user's profile data based on input user id, used in both ChatController's openProfile and EditProfileController
    func getUserFields(uid: String?, completed: @escaping (_ isSuccess: Bool, _ user: Profile?) -> ()) {
        guard let uid_ = uid else {
            completed(false, nil)
            return
        }
        
        let ref = self.REF_USERS.child(uid_)
        
        ref.keepSynced(true)
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {

                // Name, birthday, discipline, organization, profile photo, school are compulsory fields
                guard let userDict = snapshot.value as? [String: Any], let name = userDict["name"] as? String, let birthday = userDict["birthday"] as? String, let discipline = userDict["discipline"] as? String, let org = userDict["organization"] as? String, let profilePhotoUrl = userDict["profilePhoto"] as? String, let school = userDict["school"] as? String else {
                    completed(false, nil)
                    return
                }
                var tagline1 = ""
                if let t = userDict["tagline1"] as? String {
                    tagline1 = t
                }
                var tagline2 = ""
                if let t = userDict["tagline2"] as? String {
                    tagline2 = t
                }
                var location = ""
                if let l = userDict["location"] as? String {
                    location = l
                }
                var coverPhotoUrl = ""
                if let c = userDict["coverPhoto"] as? String {
                    coverPhotoUrl = c
                }

                
                // Convert birthday of "MM/DD/yyyy" to age integer
                let age = convertBirthdayToAge(birthday: birthday)
                if location == "" {
                    // User disabled location, return here without location
                    let user = Profile(uid: uid_, name: name, coverImageName: coverPhotoUrl, profileImageName: profilePhotoUrl, age: age, location: "", org: org, school: school, discipline: discipline, tagline1: tagline1, tagline2: tagline2)
                    completed(true, user)
                }
                // Convert "<lat>,<lon>" to "<City>, <State>, <Country>"
                convertLocationToCityAndCountry(location: location) { (cityCountry) in
                    // User has city country here
                    let user = Profile(uid: uid_, name: name, coverImageName: coverPhotoUrl, profileImageName: profilePhotoUrl, age: age, location: cityCountry, org: org, school: school, discipline: discipline, tagline1: tagline1, tagline2: tagline2)
                    completed(true, user)
                }
            } else {
                // User does not exist. Error
                completed(false, nil)
            }
        })
    }
    
    func updateCachedDetailsInConnections(profilePhoto: String? = nil, discipline: String? = nil, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        REF_USERS.child("\(uid)/connections").observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists() { // This user has no connections
                completed(true)
                return
            }
            guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
                completed(false)
                return
            }
            var snapsLeft = snaps.count
            var hasError = false
            for snap in snaps {
                
                // For each connection, edit your profile pic/discipline in their list of connections
                let uid2 = snap.key
                var updates: [String: Any] = [:]
                if profilePhoto != nil {
                   updates["profilePhoto"] = profilePhoto!
                }
                if discipline != nil {
                    updates["discipline"] = discipline!
                }
                
                self.REF_USERS.child("\(uid2)/connections/\(uid)").updateChildValues(updates, withCompletionBlock: { (err, ref) in
                    snapsLeft -= 1
                    hasError = err != nil
                    if snapsLeft <= 0 {
                        completed(!hasError)
                    }
                })
            }
        })
    }
    
    // MARK: Chat
    
    // Private function to get chat id from two uids
    fileprivate func getChatId(uid1: String, uid2: String) -> String {
        if uid1 < uid2 {
            return "\(uid1):\(uid2)"
        } else {
            return "\(uid2):\(uid1)"
        }
    }

    // Observes the connection names, photos and disciplines, used in ConnectionsController
    func observeConnections(completed: @escaping (_ isSuccess: Bool, _ connections: [Connection]) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/connections")
        
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
            
            var connections: [Connection] = []
            
            
            for snap in snaps {
                if let dict = snap.value as? [String: Any], let discipline = dict["discipline"] as? String, let name = dict["name"] as? String, let photo = dict["profilePhoto"] as? String {
                    let conn: Connection = Connection(uid: snap.key, name: name, profileImageName: photo, discipline: discipline)
                    connections.append(conn)
                }
            }
            completed(true, connections)
        })
        return (ref, handle)
    }
    
    // Observes the recent message by one connection, used in ConnectionsController
    func observeRecentChat(connection: Connection, completed: @escaping (_ isSuccess: Bool, _ connection: Connection?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let chatId: String = getChatId(uid1: uid, uid2: connection.uid)
        let ref: FIRDatabaseReference = REF_CHATS.child(chatId)
        
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
            
            connection.dateMatched = dateMatched
            
            let date: Date = Date(timeIntervalSince1970: timestamp)
            let isSentByYou: Bool = poster == uid
            
            connection.hasNewMessages = hasNewMessages
            let msg = ConnectionMessage(mid: mid, text: text, connection: connection, date: date, isSentByYou: isSentByYou)
            
            connection.clearMessages()
            connection.addMessage(message: msg)
            
            completed(true, connection)
        })
        return (ref, handle)
    }
    
    fileprivate func processChatSnapshot(snapshot: FIRDataSnapshot, connection: Connection, uid: String) -> Connection? {
        if !snapshot.exists() {
            return nil
        }
        
        guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
            return nil
        }
        connection.clearMessages()
        for snap in snaps {
            if let dict = snap.value as? [String: Any], let text = dict["message"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String {
                let mid: String = snap.key
                let isSentByYou: Bool = poster == uid
                let date = Date(timeIntervalSince1970: timestamp)
                let msg = ConnectionMessage(mid: mid, text: text, connection: connection, date: date, isSentByYou: isSentByYou)
                connection.addMessage(message: msg)
            }
        }
        return connection
    }
    
    // Observes all chat messags of one connection, used in ChatController
    func reobserveChatMessages(limit: UInt, connection: Connection, completed: @escaping (_ isSuccess: Bool, _ connection: Connection?) -> ()) -> (FIRDatabaseQuery, FIRDatabaseHandle) {
        
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let chatId: String = getChatId(uid1: uid, uid2: connection.uid)
        let ref: FIRDatabaseReference = REF_MESSAGES.child(chatId)
        ref.keepSynced(true)
        // Remove hasNew of this chat if user is on the chat screen
        self.seeConnectionMessages(connection: connection) { (isSuccess) in }
        
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.keepSynced(true)
        let handle = q.observe(.value, with: { snapshot in
            let conn = self.processChatSnapshot(snapshot: snapshot, connection: connection, uid: uid)
            completed(conn != nil, conn)
        })
        return (q, handle)
    }
    
    // Observes all chat messags of one connection once, used when setting up ChatController
    func observeChatMessagesOnce(connection: Connection, limit: UInt, completed: @escaping (_ isSuccess: Bool, _ connection: Connection?) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let chatId: String = getChatId(uid1: uid, uid2: connection.uid)
        let ref: FIRDatabaseReference = REF_MESSAGES.child(chatId)
        
        // Remove hasNew of this chat if user is on the chat screen
        self.seeConnectionMessages(connection: connection) { (isSuccess) in }
        
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.observeSingleEvent(of: .value, with: { snapshot in
            q.removeAllObservers()
            let conn = self.processChatSnapshot(snapshot: snapshot, connection: connection, uid: uid)
            completed(conn != nil, conn)
        })
    }
    
    // Adds a chat message to the messages with a connection, used in ChatController
    func addChatMessage(connection: Connection, text: String, completed: @escaping (_ isSuccess: Bool, _ connection: Connection?) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false, nil)
            return
        }
        let poster = uid
        let chatId: String = getChatId(uid1: uid, uid2: connection.uid)
        let timestamp = Date().timeIntervalSince1970
        
        // Creates new message in two places: Messages and Chats (lastMessage)
        // Do a multipath update to preserve atomicity, even for offline updates
        
        let messagesRef: FIRDatabaseReference = REF_MESSAGES.child(chatId).childByAutoId()
        let mid = messagesRef.key
        let newMessage: [String: Any] = ["message": text, "timestamp": timestamp, "poster": poster]
        
        REF_BASE.updateChildValues(["messages/\(chatId)/\(mid)": newMessage, "chats/\(chatId)/mid": mid, "chats/\(chatId)/lastMessage": text, "chats/\(chatId)/timestamp": timestamp, "chats/\(chatId)/poster": poster, "chats/\(chatId)/hasNew:\(uid)": false, "chats/\(chatId)/hasNew:\(connection.uid)": true]) { (err, ref) in
            if (err != nil) {
                completed(false, nil)
                return
            }
            // Add to notification queue
            self.addToNotificationQueue(type: TokenType.CONNECTION, posterUid: uid, recipientUid: connection.uid, tid: "", title: "Connection", body: text)
            
            // TODO: Increment badgeCount of the other person if his hasNew is false before setting
            
            let msg = ConnectionMessage(mid: mid, text: text, connection: connection, date: Date(timeIntervalSince1970: timestamp), isSentByYou: true)
            connection.addMessage(message: msg)
            completed(true, connection)
        }
    }
    
    // Called whenever a user clicks on a connection that is not previously seen to update the connection's
    // message to seen. Used in ConnectionsController.
    func seeConnectionMessages(connection: Connection, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let chatId: String = getChatId(uid1: uid, uid2: connection.uid)
        REF_CHATS.child(chatId).updateChildValues(["hasNew:\(uid)": false]) { (err, ref) in
            completed(err == nil)
        }
    }
    
    // MARK: Remote notifications Queue
    
    // Upon sending a message in topic or chat, add a notification to the Queue for server workers to process
    func addToNotificationQueue(type: TokenType, posterUid: String, recipientUid: String, tid: String, title: String, body: String) {
        // No need to async callback because notifications are not guaranteed anyway
        let dict = ["type": type.rawValue, "posterUid": posterUid, "recipientUid": recipientUid, "tid": tid, "title": title, "body": body]
        REF_QUEUE.childByAutoId().setValue(dict)
    }
    
    // MARK: Test functions
    
    func connectWithAll() {
        // Get all uids first
        guard let uid1 = getStoredUid() else {
            return
        }
        REF_USERS.observeSingleEvent(of: .value, with: { snapshot in
            let snaps = snapshot.children.allObjects as! [FIRDataSnapshot]
            let uids = snaps.map({ (snap) -> String in
                return snap.key
            })
            // Get uid1 details
            self.REF_USERS.child(uid1).observeSingleEvent(of: .value, with: { snapshot2 in
                let dict = snapshot2.value as! [String: Any]
                let myDiscipline = dict["discipline"] as! String
                let myName = dict["name"] as! String
                let myProfilePhoto = dict["profilePhoto"] as! String
                for uid2 in uids {
                    // Grab their info
                    if uid2 == uid1 { continue }
                    self.REF_USERS.child(uid2).observeSingleEvent(of: .value, with: { snapshot3 in
                        let otherDict = snapshot3.value as! [String: Any]
                        let otherDiscipline = otherDict["discipline"] as! String
                        let otherName = otherDict["name"] as! String
                        let otherProfilePhoto = otherDict["profilePhoto"] as! String
                        self.REF_USERS.child("\(uid1)/connections/\(uid2)").setValue(["discipline": otherDiscipline, "name": otherName, "profilePhoto": otherProfilePhoto])
                        self.REF_USERS.child("\(uid2)/connections/\(uid1)").setValue(["discipline": myDiscipline, "name": myName, "profilePhoto": myProfilePhoto])
                        let chatId = self.getChatId(uid1: uid1, uid2: uid2)
                        self.REF_CHATS.child(chatId).setValue(["dateMatched": "11/10/2016", "hasNew:\(uid1)": true, "hasNew:\(uid2)": true, "lastMessage": "", "mid": "", "poster": "", "timestamp": Date().timeIntervalSince1970])
                    
                    })
                    
                    
                    
                }
                
            })
        })
    }
    
    func addConnectionsTest() {
        let uid1 = getStoredUid()!
        for i in 19...36 {
            let uid2 = "2011800203281" + String(i)
            addConnection(uid1: uid1, uid2: uid2)
        }
    }
    
    func addConnection(uid1: String, uid2: String) {
        // Get uid1 and uid2 details
//        REF_USERS.child("\(uid1)/connections/\(uid2)").setValue(["discipline": "Business", "name": "Leonard", "profilePhoto": "https://firebasestorage.googleapis.com/v0/b/app-abdf9.appspot.com/o/user%2F1250226885021203%2Fprofile_photo?alt=media&token=c684e1d1-2f6d-48ee-8905-77c90f67cc31"])
//        REF_USERS.child("\(uid2)/connections/\(uid1)").setValue(["discipline": "East Asian Studies", "name": "Test", "profilePhoto": "https://firebasestorage.googleapis.com/v0/b/app-abdf9.appspot.com/o/user%2F1250226885021203%2Fprofile_photo?alt=media&token=c684e1d1-2f6d-48ee-8905-77c90f67cc31"])
        let chatId = getChatId(uid1: uid1, uid2: uid2)
        REF_CHATS.child(chatId).setValue(["dateMatched": "11/10/2016", "hasNew:\(uid1)": true, "hasNew:\(uid2)": true, "lastMessage": "", "mid": "", "poster": "", "timestamp": Date().timeIntervalSince1970])
    }
    
}
