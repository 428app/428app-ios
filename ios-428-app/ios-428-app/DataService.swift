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
    
    // To be called whenever user logs out
    func removeAllObservers() {
        _REF_BASE.removeAllObservers()
        _REF_USER.removeAllObservers()
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
    
    // Called in LoginController to update user's location, after location manager gets it
    func updateUserLocation(lat: Double, lon: Double, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let timeNow = Date().timeIntervalSince1970
        self.REF_USER.child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USER.child(uid).updateChildValues(["location": "\(lat), \(lon)", "lastSeen": timeNow], withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error.
                completed(false)
            }
        })
    }
    
    // Updates user's last seen in AppDelegate's applicationDidBecomeActive
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
    
    // Update user's profile data called in IntroController and SettingControllers
    func updateUserFields(organization: String?, school: String?, discipline: String?, tagline1: String?, tagline2: String?, completed: @escaping (_ isSuccess: Bool) -> ()) {
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
    
    
}
