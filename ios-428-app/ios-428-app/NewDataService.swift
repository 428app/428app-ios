//
//  NewDataService.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/23/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging
import FBSDKCoreKit
import FBSDKLoginKit

// Root of DB: Either real_db or test_db
private let DB_ROOT = "real_db"

class NewDataService {

    static let ds = NewDataService()
    
    fileprivate var _REF_BASE = FIRDatabase.database().reference().child(DB_ROOT)
    fileprivate var _REF_USERS = FIRDatabase.database().reference().child("\(DB_ROOT)/users")
    fileprivate var _REF_USERSETTINGS = FIRDatabase.database().reference().child("\(DB_ROOT)/userSettings")
    fileprivate var _REF_PRIVATEMESSAGES = FIRDatabase.database().reference().child("\(DB_ROOT)/privateMessages")
    fileprivate var _REF_PRIVATECHATS = FIRDatabase.database().reference().child("\(DB_ROOT)/privateChats")
    fileprivate var _REF_CLASSROOMS = FIRDatabase.database().reference().child("\(DB_ROOT)/classrooms")
    fileprivate var _REF_CLASSROOMMESSAGES = FIRDatabase.database().reference().child("\(DB_ROOT)/classroomMessages")
    fileprivate var _REF_QUESTIONS = FIRDatabase.database().reference().child("\(DB_ROOT)/questions")
    fileprivate var _REF_QUEUE = FIRDatabase.database().reference().child("\(DB_ROOT)/queue/tasks") // Queue for notifications to be sent out
    
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
    
    var REF_USERSETTINGS: FIRDatabaseReference {
        get {
            return _REF_USERSETTINGS
        }
    }
    
    var REF_PRIVATEMESSAGES: FIRDatabaseReference {
        get {
            return _REF_PRIVATEMESSAGES
        }
    }
    
    var REF_PRIVATECHATS: FIRDatabaseReference {
        get {
            return _REF_PRIVATECHATS
        }
    }
    
    var REF_CLASSROOMS: FIRDatabaseReference {
        get {
            return _REF_CLASSROOMS
        }
    }
    
    var REF_CLASSROOMMESSAGES: FIRDatabaseReference {
        get {
            return _REF_PRIVATEMESSAGES
        }
    }
    
    var REF_QUESTIONS: FIRDatabaseReference {
        get {
            return _REF_QUESTIONS
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
        _REF_USERSETTINGS.removeAllObservers()
        _REF_PRIVATEMESSAGES.removeAllObservers()
        _REF_PRIVATECHATS.removeAllObservers()
        _REF_CLASSROOMS.removeAllObservers()
        _REF_CLASSROOMMESSAGES.removeAllObservers()
        _REF_QUESTIONS.removeAllObservers()
        _REF_QUEUE.removeAllObservers()
    }
    
    // MARK: User
    
    func logout(completed: @escaping (_ isSuccess: Bool) -> ()) {
        if let auth = FIRAuth.auth(), let _ = try? auth.signOut() {
            self.removeAllObservers()
            log.info("User logged out")
            FIRMessaging.messaging().disconnect()
            FBSDKLoginManager().logOut()
            setIsLoggedIn(isLoggedIn: false, completed: { (isSuccess) in
                completed(isSuccess)
            })
            return
        }
        completed(false)
    }
    
    // Maintaining user's logged in state allows us to deliver our remote notifications correctly
    fileprivate func setIsLoggedIn(isLoggedIn: Bool, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        REF_USERSETTINGS.child("\(uid)/isLoggedIn").setValue(isLoggedIn, withCompletionBlock: { (err, ref) in
            completed(err == nil)
        })
    }
    
    // Called in LoginController to create new user or log existing user in
    // Note: Only mostly updates Facebook details, other details such as pushToken and location are being updated by other calls
    func loginFirebaseUser(fbid: String, name: String, birthday: String, pictureUrl: String, timezone: Double, completed: @escaping (_ isSuccess: Bool, _ isFirstTimeUser: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false, true)
            return
        }
        
        // Update name locally
        saveName(name: name)
        
        let timeNow = Date().timeIntervalSince1970
        var user: [String: Any] = ["fbid": fbid, "name": name, "birthday": birthday, "profilePhoto": pictureUrl, "timezone": timezone, "lastSeen": timeNow]
        
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
                // Update isLoggedIn in user settings
                self.setIsLoggedIn(isLoggedIn: true, completed: { (loginSuccess) in })
                
            } else {
                // Create new user
                user["badgeCount"] = 0
                user["hasNewBadge"] = false
                user["HasNewClassroom"] = false
                let userSettings = ["dailyAlert": true, "privateMessages": true, "classroomMessages": true, "inAppNotifications": true, "isLoggedIn": true]
                
                self.REF_BASE.updateChildValues(["/users/\(uid)": user, "/userSettings/\(uid)": userSettings], withCompletionBlock: { (err, ref) in
                    completed(err == nil, true)
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
                // Might as well update last seen as well
                // Location is in the format "lat, lon"
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
    
    // Updates own last seen in AppDelegate's applicationDidBecomeActive, when a user opens the app from background
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
    
    // Updates own profile textual data. Called in IntroController and Edit Profile Controllers
    func updateUserFields(discipline: String? = nil, school: String? = nil, organization: String? = nil, tagline: String? = nil, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        var userFields: [String: Any] = [:]
        if discipline != nil {
            userFields["discipline"] = discipline!
        }
        if school != nil {
            userFields["school"] = school!
        }
        if organization != nil {
            userFields["organization"] = organization!
        }
        if tagline != nil {
            userFields["tagline"] = tagline!.lowercaseFirstLetter()
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
    
    // Similar to updateUserFields, except this updates profile image data. This is not called by the client directly, but by StorageService after uploading of image is complete.
    func updateUserPhoto(profilePhotoUrl: String, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USERS.child(uid).updateChildValues(["profilePhoto": profilePhotoUrl], withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error
                completed(false)
            }
        })
    }
    
    // Retrive user's profile data based on input user id.
    // View other profiles in ChatController's openProfile or own profile in Edit Profile Controllers
    func getUserFields(uid: String?, completed: @escaping (_ isSuccess: Bool, _ user: Profile?) -> ()) {
        guard let uid_ = uid else {
            completed(false, nil)
            return
        }
        
        let ref = self.REF_USERS.child(uid_)
        ref.keepSynced(true)
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                
                // Name, birthday, discipline, profile photo are compulsory fields
                guard let userDict = snapshot.value as? [String: Any], let name = userDict["name"] as? String, let birthday = userDict["birthday"] as? String, let discipline = userDict["discipline"] as? String, let profilePhotoUrl = userDict["profilePhoto"] as? String else {
                    completed(false, nil)
                    return
                }
                var school = ""
                if let s = userDict["school"] as? String {
                    school = s
                }
                var org = ""
                if let o = userDict["organization"] as? String {
                    org = o
                }
                var tagline = ""
                if let t = userDict["tagline"] as? String {
                    tagline = t
                }
                var location = ""
                if let l = userDict["location"] as? String {
                    location = l
                }
                // TODO: Test if badges and classrooms work
                var badges = [String]()
                if let b = userDict["badges"] as? [String: Bool] {
                    badges = [String](b.keys)
                }
                var classrooms = [String]()
                if let c = userDict["classrooms"] as? [String: Bool] {
                    classrooms = [String](c.keys)
                }
                // Convert birthday of "MM/DD/yyyy" to age integer
                let age = convertBirthdayToAge(birthday: birthday)
                if location == "" {
                    // User disabled location, return here without location
                    let user = Profile(uid: uid_, name: name, profileImageName: profilePhotoUrl, discipline: discipline, age: age, location: "", school: school, org: org, tagline: tagline, badges: badges, classrooms: classrooms)
                    completed(true, user)
                }
                // Convert "<lat>,<lon>" to "<City>, <State>, <Country>"
                convertLocationToCityAndCountry(location: location) { (cityCountry) in
                    // User has city country here
                    let user = Profile(uid: uid_, name: name, profileImageName: profilePhotoUrl, discipline: discipline, age: age, location: cityCountry, school: school, org: org, tagline: tagline, badges: badges, classrooms: classrooms)
                    completed(true, user)
                }
            } else {
                // User does not exist. Error
                completed(false, nil)
            }
        })
    }
    
    // Whenever a user updates his details, be it picture in StorageService or textual info in EditProfessionalController, the changes are updated in the cache of the people he private messages
    func updateCachedDetailsInPrivates(profilePhoto: String? = nil, discipline: String? = nil, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        REF_USERS.child("\(uid)/privates").observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists() { // This user has no private messages yet
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
                
                // For each private, edit your profile pic/discipline in their list of privates
                let uid2 = snap.key
                var updates: [String: Any] = [:]
                if profilePhoto != nil {
                    updates["profilePhoto"] = profilePhoto!
                }
                if discipline != nil {
                    updates["discipline"] = discipline!
                }
                
                self.REF_USERS.child("\(uid2)/privates/\(uid)").updateChildValues(updates, withCompletionBlock: { (err, ref) in
                    snapsLeft -= 1
                    hasError = err != nil
                    if snapsLeft <= 0 {
                        completed(!hasError)
                    }
                })
            }
        })
    }

}
