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
    private var _REF_BASE = FIRDatabase.database().reference()
    
    var REF_BASE: FIRDatabaseReference {
        get {
            return _REF_BASE
        }
    }
    
    // To be called whenever user logs out
    func removeAllObservers() {
        _REF_BASE.removeAllObservers()
    }
    
    
}
