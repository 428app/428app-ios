//
//  Rating.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Rating {
    
    fileprivate var _ratingName: String
    fileprivate var _userVotedFor: Profile?
    
    init(ratingName: String, userVotedFor: Profile? = nil) {
        _ratingName = ratingName
        _userVotedFor = userVotedFor // Can be empty
    }
    
    var ratingName: String {
        get {
            return _ratingName
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
