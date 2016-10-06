//
//  Match.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Match {
    
    private var _userPicUrl: String! // TODO: Change this string to our S3 string
    private var _username: String!
    private var _recentMsg: String!
    private var _lastSentTime: Double!
    
    // Computed variables
    private var _lastSentTimeString: String!
    
    init(userPicUrl: String, username: String, recentMsg: String, lastSentTime: Double) {
        self._userPicUrl = userPicUrl
        self._username = username
        self._recentMsg = recentMsg
        self._lastSentTime = lastSentTime
        self._lastSentTimeString = "" // TODO: Compute this last sent time
    }
    
    var userPicUrl: String {
        get {
            return self._userPicUrl
        }
    }
    
    var username: String {
        get {
            return self._username
        }
    }
    
    var recentMsg: String {
        get {
            return self._recentMsg
        }
    }
    
    var lastSentTime: Double {
        get {
            return self._lastSentTime
        }
    }
    
    var lastSentTimeString: String {
        get {
            return self._lastSentTimeString
        }
    }
}
