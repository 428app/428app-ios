//
//  DataService.swift
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

// Houses all the Firebase refs for the various extensions (Services) to call

// Root of DB: Either real_db or test_db
let DB_ROOT = "real_db"
//let DB_ROOT = "test_db"

class DataService {

    static let ds = DataService()
    
    fileprivate var _REF_BASE = FIRDatabase.database().reference().child(DB_ROOT)
    fileprivate var _REF_USERS = FIRDatabase.database().reference().child("\(DB_ROOT)/users")
    fileprivate var _REF_USERSETTINGS = FIRDatabase.database().reference().child("\(DB_ROOT)/userSettings")
    fileprivate var _REF_INBOXMESSAGES = FIRDatabase.database().reference().child("\(DB_ROOT)/inboxMessages")
    fileprivate var _REF_INBOX = FIRDatabase.database().reference().child("\(DB_ROOT)/inbox")
    fileprivate var _REF_CLASSROOMS = FIRDatabase.database().reference().child("\(DB_ROOT)/classrooms")
    fileprivate var _REF_CLASSROOMMESSAGES = FIRDatabase.database().reference().child("\(DB_ROOT)/classroomMessages")
    fileprivate var _REF_QUESTIONS = FIRDatabase.database().reference().child("\(DB_ROOT)/questions")
    fileprivate var _REF_DIDYOUKNOWS = FIRDatabase.database().reference().child("\(DB_ROOT)/didyouknows")
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
    
    var REF_INBOXMESSAGES: FIRDatabaseReference {
        get {
            return _REF_INBOXMESSAGES
        }
    }
    
    var REF_INBOX: FIRDatabaseReference {
        get {
            return _REF_INBOX
        }
    }
    
    var REF_CLASSROOMS: FIRDatabaseReference {
        get {
            return _REF_CLASSROOMS
        }
    }
    
    var REF_CLASSROOMMESSAGES: FIRDatabaseReference {
        get {
            return _REF_CLASSROOMMESSAGES
        }
    }
    
    var REF_QUESTIONS: FIRDatabaseReference {
        get {
            return _REF_QUESTIONS
        }
    }
    
    var REF_DIDYOUKNOWS: FIRDatabaseReference {
        get {
            return _REF_DIDYOUKNOWS
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
        _REF_INBOXMESSAGES.removeAllObservers()
        _REF_INBOX.removeAllObservers()
        _REF_CLASSROOMS.removeAllObservers()
        _REF_CLASSROOMMESSAGES.removeAllObservers()
        _REF_QUESTIONS.removeAllObservers()
        _REF_DIDYOUKNOWS.removeAllObservers()
        _REF_QUEUE.removeAllObservers()
    }
}
