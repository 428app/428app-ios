//
//  UserService.swift
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

// Extends DataService to house User calls
extension DataService {
    
    // MARK: User
    
    func logout(completed: @escaping (_ isSuccess: Bool) -> ()) {
        if let auth = FIRAuth.auth(), let _ = try? auth.signOut() {
            self.removeAllObservers()
            log.info("User logged out")
            FIRMessaging.messaging().disconnect()
            FBSDKLoginManager().logOut()
            setIsLoggedIn(isLoggedIn: false, completed: { (isSuccess) in
                completed(isSuccess)
                return
            })
            return
        } else {
            completed(false)
            return
        }
    }
    
    // Maintaining user's logged in state allows us to deliver our remote notifications correctly
    fileprivate func setIsLoggedIn(isLoggedIn: Bool, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        REF_USERSETTINGS.child("\(uid)").updateChildValues(["isLoggedIn": isLoggedIn], withCompletionBlock: { (err, ref) in
            completed(err == nil)
            return
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
        
        // Only update profile photo if this user does not have a profile photo
        var user: [String: Any] = ["fbid": fbid, "name": name, "birthday": birthday, "timezone": timezone, "lastSeen": timeNow]
        
        self.REF_USERS.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            
            if snapshot.exists() {
                // Check if user has already filled in at least org, school and discipline, if not label first time user
                var isFirstTimeUser = true
                if let userDict = snapshot.value as? [String: Any], let _ = userDict["organization"] as? String, let _ = userDict["school"] as? String, let _ = userDict["discipline"] as? String {
                    isFirstTimeUser = false
                }
                
                // Only update profile photo provided by Facebook via this login if this user does not have a profile photo
                if let userDict = snapshot.value as? [String: Any] {
                    if userDict["profilePhoto"] == nil {
                        user["profilePhoto"] = pictureUrl
                    }
                }
                
                // Update isLoggedIn in user settings
                self.setIsLoggedIn(isLoggedIn: true, completed: { (loginSuccess) in })
                
                // Update user info
                self.REF_USERS.child(uid).updateChildValues(user, withCompletionBlock: { (err, ref) in
                    completed(err == nil, isFirstTimeUser)
                    return
                })
                
            } else {
                // Create new user
                user["pushCount"] = 0
                user["hasNewBadge"] = false
                user["hasNewClassroom"] = false
                let userSettings = ["dailyAlert": true, "inboxMessages": true, "classroomMessages": true, "inAppNotifications": true, "isLoggedIn": true]
                
                self.REF_BASE.updateChildValues(["/users/\(uid)": user, "/userSettings/\(uid)": userSettings], withCompletionBlock: { (err, ref) in
                    completed(err == nil, true)
                    return
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
                    return
                })
            } else {
                // User does not exist. Error.
                completed(false)
                return
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
                    return
                })
            } else {
                // User does not exist. Error
                completed(false)
                return
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
                    return
                })
            } else {
                // User does not exist. Error
                completed(false)
                return
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
                self.REF_USERS.child("\(uid)/profilePhoto").setValue(profilePhotoUrl, withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                    return
                })
            } else {
                // User does not exist. Error
                completed(false)
                return
            }
        })
    }
    
    // Retrive user's profile data based on input user id.
    // View other profiles in ChatInboxController's openProfile or own profile in Edit Profile Controllers
    // Also used in ClassroomService to get user fields
    func getUserFields(uid: String?, completed: @escaping (_ isSuccess: Bool, _ user: Profile?) -> ()) {
        guard let uid_ = uid else {
            completed(false, nil)
            return
        }
        
        let ref = self.REF_USERS.child(uid_)
        
        ref.keepSynced(true)
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            log.info("observed user")
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
                if let c = userDict["classrooms"] as? [String: [String: Any]] {
                    // Iterate through classrooms to get disciplines
                    for (_, cidData) in c {
                        if let classroomDiscipline = cidData["discipline"] as? String {
                            classrooms.append(classroomDiscipline)
                        }
                    }
                }
                // Convert birthday of "MM/DD/yyyy" to age integer
                let age = convertBirthdayToAge(birthday: birthday)
                if location == "" {
                    // User disabled location, return here without location
                    let user = Profile(uid: uid_, name: name, profileImageName: profilePhotoUrl, discipline: discipline, age: age, location: "", school: school, org: org, tagline: tagline, badges: badges, classrooms: classrooms)
                    completed(true, user)
                    return
                }
                // Convert "<lat>,<lon>" to "<City>, <State>, <Country>"
                convertLocationToCityAndCountry(location: location) { (cityCountry) in
                    // User has city country here
                    let user = Profile(uid: uid_, name: name, profileImageName: profilePhotoUrl, discipline: discipline, age: age, location: cityCountry, school: school, org: org, tagline: tagline, badges: badges, classrooms: classrooms)
                    completed(true, user)
                    return
                }
            } else {
                // User does not exist. Error
                completed(false, nil)
                return
            }
        })
    }
    
    // Whenever a user updates his details, be it picture in StorageService or textual info in EditProfessionalController, the changes are updated in the cache of the people he private messages
    func updateCachedDetailsInInboxes(profilePhoto: String? = nil, discipline: String? = nil, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        REF_USERS.child("\(uid)/inbox").observeSingleEvent(of: .value, with: { snapshot in
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
                
                // For each inbox, edit your profile pic/discipline in their list of inboxes
                let uid2 = snap.key
                var updates: [String: Any] = [:]
                if profilePhoto != nil {
                    updates["profilePhoto"] = profilePhoto!
                }
                if discipline != nil {
                    updates["discipline"] = discipline!
                }
                
                self.REF_USERS.child("\(uid2)/inbox/\(uid)").updateChildValues(updates, withCompletionBlock: { (err, ref) in
                    snapsLeft -= 1
                    hasError = err != nil
                    if snapsLeft <= 0 {
                        completed(!hasError)
                        return
                    }
                })
            }
        })
    }
    
    // MARK: User Settings
    
    // Updates user settings whenever a user toggles the various settings in SettingsController
    func updateUserSettings(dailyAlert: Bool, inboxMessages: Bool, classroomMessages: Bool, inAppNotifications: Bool, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        // Replace all existing settings
        let settings: [String: Bool] = ["dailyAlert": dailyAlert, "inboxMessages": inboxMessages, "classroomMessages": classroomMessages, "inAppNotifications": inAppNotifications]
        
        REF_USERSETTINGS.child(uid).updateChildValues(settings, withCompletionBlock: { (err, ref) in
            completed(err == nil)
            return
        })
    }
    
    // Used in SettingsController to get user settings
    func getUserSettings(completed: @escaping (_ settings: [String: Bool]?) -> ()) {
        guard let uid = getStoredUid() else {
            completed(nil)
            return
        }
        
        let ref = REF_USERSETTINGS.child(uid)
        ref.keepSynced(true)
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists() {
                completed(nil)
                return
            }
            guard let dict = snapshot.value as? [String: Bool], let dailyAlert = dict["dailyAlert"], let inboxMessages = dict["inboxMessages"], let classroomMessages = dict["classroomMessages"], let inAppNotifications = dict["inAppNotifications"] else {
                completed(nil)
                return
            }
            // These are settings are values mapped directly to the keys that will be displayed on the frontend
            // Note: The keys must be named exactly as you want them to appear on the frontend
            let settings = ["Daily alert": dailyAlert, "Private messages": inboxMessages, "Classroom messages": classroomMessages, "In-app notifications": inAppNotifications]
            completed(settings)
            return
        })
    }
}
