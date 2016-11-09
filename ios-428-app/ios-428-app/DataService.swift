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
    fileprivate var _REF_USER = FIRDatabase.database().reference().child("/user")
    fileprivate var _REF_CHAT = FIRDatabase.database().reference().child("/chat")
    
    var REF_BASE: FIRDatabaseReference {
        get {
            return _REF_BASE
        }
    }
    
    var REF_USER: FIRDatabaseReference {
        get {
            return _REF_USER
        }
    }
    
    var REF_CHAT: FIRDatabaseReference {
        get {
            return _REF_CHAT
        }
    }
    
    // To be called whenever user logs out
    func removeAllObservers() {
        _REF_BASE.removeAllObservers()
        _REF_USER.removeAllObservers()
        _REF_CHAT.removeAllObservers()
    }
    
    // MARK: User
    
    func logout(completed: (_ isSuccess: Bool) -> ()) {
        if let auth = FIRAuth.auth(), let _ = try? auth.signOut() {
            FBSDKLoginManager().logOut()
            completed(true)
            return
        }
        completed(false)
    }
    
    // Called in LoginController to create new user or log existing user in
    func loginFirebaseUser(name: String, birthday: String, pictureUrl: String, timezone: Double, completed: @escaping (_ isSuccess: Bool, _ isFirstTimeUser: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false, true)
            return
        }
        let timeNow = Date().timeIntervalSince1970
        let user: [String: Any] = ["name": name, "birthday": birthday, "profilePhoto": pictureUrl, "timezone": timezone, "lastSeen": timeNow]
        self.REF_USER.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                // Check if user has already filled in at least org, school and discipline, if not label first time user
                guard let userDict = snapshot.value as? [String: Any], let _ = userDict["organization"] as? String, let _ = userDict["school"] as? String, let _ = userDict["discipline"] as? String else {
                    completed(true, true)
                    return
                }
                completed(true, false)
            } else {
                // Create new user
                self.REF_USER.child(uid).setValue(user, withCompletionBlock: { (error, ref) in
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
        self.REF_USER.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USER.child(uid).updateChildValues(["location": "\(lat),\(lon)", "lastSeen": timeNow], withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error.
                completed(false)
            }
        })
    }
    
    // Updates own last seen in AppDelegate's applicationDidBecomeActive
    func updateUserLastSeen(completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            return
        }
        let timeNow = Date().timeIntervalSince1970
        self.REF_USER.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USER.child(uid).updateChildValues(["lastSeen": timeNow], withCompletionBlock: { (error, ref) in
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
        self.REF_USER.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USER.child(uid).updateChildValues(userFields, withCompletionBlock: { (error, ref) in
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
        self.REF_USER.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USER.child(uid).updateChildValues(userPhotos, withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error
                completed(false)
            }
        })
    }
    
    // Retrive user's profile data based on input user id
    func getUserFields(uid: String?, completed: @escaping (_ isSuccess: Bool, _ user: Profile?) -> ()) {
        guard let uid_ = uid else {
            completed(false, nil)
            return
        }
        self.REF_USER.child(uid_).observeSingleEvent(of: .value, with: { snapshot in
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
    
    // MARK: Chat
    
    // Private function to get chat id from two uids
    fileprivate func getChatId(uid1: String, uid2: String) -> String {
        if uid1 < uid2 {
            return "\(uid1):\(uid2)"
        } else {
            return "\(uid2):\(uid1)"
        }
    }
    
    // Retrieve messages between self and connection
    // Takes in connection (with no messages), pulls messages from server and populate connection
//    func getChat(connection: Connection, completed: @escaping (_ isSuccess: Bool, _ connection: Connection?) -> ()) {
//        guard let uid = getStoredUid() else {
//            completed(false, nil)
//            return
//        }
//        let chatId: String = getChatId(uid1: uid, uid2: connection.uid)
//        self.REF_CHAT.child(chatId).observeSingleEvent(of: .value, with: { snapshot in
//            if snapshot.exists() {
//                guard let chatDict = snapshot.value as? [String: Any], let recent = chatDict["recent"] as? [String: Any], let dateMatched = chatDict["dateMatched"] as? String, let messages = chatDict["messages"] as? [String: [String: Any]] else {
//                    completed(false, nil)
//                    return
//                }
//                // TODO: Parse it into connection and output
//                log.info("\(messages)")
//            } else {
//                // Chat does not exist. Error
//                completed(false, nil)
//            }
//        })
//    }
    
    
    // Observes the connection names, photos and disciplines, used in ConnectionsController
    func observeConnections(completed: @escaping (_ isSuccess: Bool, _ connections: [Connection]) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USER.child("\(uid)/connections")
        
        
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
                if let dict = snap.value as? [String: Any], let discipline = dict["d"] as? String, let name = dict["n"] as? String, let photo = dict["p"] as? String {
                    let conn: Connection = Connection(uid: snap.key, name: name, profileImageName: photo, disciplineImageName: discipline)
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
        let ref: FIRDatabaseReference = REF_CHAT.child(chatId)
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                completed(false, nil)
                return
            }
            
            guard let dict = snapshot.value as? [String: Any], let mid = dict["mid"] as? String, let text = dict["lastMessage"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String, let dateMatched = dict["dateMatched"] as? String else {
                completed(false, nil)
                return
            }
            
            connection.dateMatched = dateMatched
            
            let date: Date = Date(timeIntervalSince1970: timestamp)
            let isSender: Bool = poster == uid
            
            let msg = Message(mid: mid, text: text, connection: connection, date: date, isSender: isSender)
            
            connection.clearMessages()
            connection.addMessage(message: msg)
            
            completed(true, connection)
        })
        return (ref, handle)
    }
    
//    func getConnections(completed: @escaping (_ isSuccess: Bool, _ connections: [Connection]) -> ()){
//        guard let uid = getStoredUid() else {
//            completed(false, [])
//            return
//        }
//        
//        self.REF_USER.child(uid).observeSingleEvent(of: .value, with: { snapshot in
//            if snapshot.exists() {
//                // Grab connections, and for each of those connections, check chat and grab recent and date matched
//                guard let userDict = snapshot.value as? [String: Any], let connections = userDict["connections"] as? [String: [String: Any]] else {
//                    completed(false, [])
//                    return
//                }
//                for (cid, dict) in connections {
//                    guard let name = dict["n"] as? String, let discipline = dict["d"] as? String, let picture = dict["p"] as? String else {
//                        continue
//                    }
//                    // Map discipline name to packaged discipline icon image name
//                    var conn: Connection = Connection(uid: cid, name: name, profileImageName: picture, disciplineImageName: getDisciplineIconForDiscipline(discipline: discipline))
//                    
//                    let chatId: String = getChatId(uid1: uid, uid2: cid)
//                    // Get recent, date matched, (and might as well get all messages here)
//                    
//                    
//                    
//                }
//                
//            } else {
//                // User does not exist. Error
//                completed(false, [])
//            }
//            
//        })
//        
//        // For each connection, fill in
//    }
    
    
}
