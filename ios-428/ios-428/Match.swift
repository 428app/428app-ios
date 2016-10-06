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
    private var _discipline: String! // Discipline label exactly matches icon name in Assets
    
    init(userPicUrl: String, username: String, recentMsg: String, discipline: String) {
        self._userPicUrl = userPicUrl
        self._username = username
        self._recentMsg = recentMsg
        self._discipline = discipline
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
    
    var discipline: String {
        get {
            return self._discipline
        }
    }
}
