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
    
    func createFirebaseUser(fbid: String, name: String, birthday: String, pictureUrl: String, completed: @escaping (_ isSuccess: Bool) -> ()) {
        let timeNow = Date().timeIntervalSince1970
        let user: [String: Any] = ["name": name, "birthday": birthday, "profilePhoto": pictureUrl, "lastSeen": timeNow]
        self.REF_USER.child(fbid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                // User already exists, update server details and login
                self.REF_USER.child(fbid).updateChildValues(user, withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            } else {
                // Create new user
                self.REF_USER.child(fbid).setValue(user, withCompletionBlock: { (error, ref) in
                    completed(error == nil)
                })
            }
        })
    }
}
