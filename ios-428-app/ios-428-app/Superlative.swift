//
//  Superlative.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Superlative {
    
    fileprivate var _superlativeName: String
    fileprivate var _userVotedFor: Profile?
    
    init(superlativeName: String, userVotedFor: Profile? = nil) {
        _superlativeName = superlativeName
        _userVotedFor = userVotedFor // Can be empty
    }
    
    var superlativeName: String {
        get {
            return _superlativeName
        }
    }
    
    var userVotedFor: Profile? {
        get {
            return _userVotedFor
        }
        set(profile) {
            _userVotedFor = profile
        }
    }
}
