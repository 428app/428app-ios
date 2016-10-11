//
//  ChatItem.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class ChatItem {
    
    private var _message: String!
    private var _isOther: Bool!
    private var _otherPic: String? // Pic of other if isOther is true
    
    init(message: String, isOther: Bool, otherPic: String?) {
        self._message = message
        self._isOther = isOther
        self._otherPic = otherPic
    }
    
    var message: String {
        get {
            return self._message
        }
    }
    
    var isOther: Bool {
        get {
            return self._isOther
        }
    }
    
    var otherPic: String? {
        get {
            return self._otherPic
        }
    }
}
