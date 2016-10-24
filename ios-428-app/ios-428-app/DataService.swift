//
//  DataService.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/23/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth


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
    
    // Called in LoginController to create new user or log existing user in
    func loginFirebaseUser(fbid: String, name: String, birthday: String, pictureUrl: String, timezone: Double, completed: @escaping (_ isSuccess: Bool, _ isFirstTimeUser: Bool) -> ()) {
        let timeNow = Date().timeIntervalSince1970
        let user: [String: Any] = ["name": name, "birthday": birthday, "profilePhoto": pictureUrl, "timezone": timezone, "lastSeen": timeNow]
        self.REF_USER.child(fbid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                // User already exists, return
                completed(true, false)
            } else {
                // Create new user
                self.REF_USER.child(fbid).setValue(user, withCompletionBlock: { (error, ref) in
                    completed(error == nil, true)
                })
            }
        })
    }
    
    // Called in LoginController to update user's location, after location manager gets it
    func updateUserLocation(fbid: String, lat: Double, lon: Double, completed: @escaping (_ isSuccess: Bool) -> ()) {
        let timeNow = Date().timeIntervalSince1970
        self.REF_USER.child(fbid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USER.child(fbid).updateChildValues(["location": "\(lat), \(lon)", "lastSeen": timeNow], withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error.
                completed(false)
            }
        })
    }
    
    // Updates user's last seen in AppDelegate's
    func updateUserLastSeen(fbid: String, completed: @escaping (_ isSuccess: Bool) -> ()) {
        if fbid == "" { // User's fbid not initialized yet
            return
        }
        let timeNow = Date().timeIntervalSince1970
        self.REF_USER.child(fbid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.REF_USER.child(fbid).updateChildValues(["lastSeen": timeNow], withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // User does not exist. Error
                completed(false)
            }
        })
    }
    
}
