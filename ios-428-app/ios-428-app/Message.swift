//
//  Message.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/15/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Message {

    fileprivate var _mid: String
    fileprivate var _text: String
    fileprivate var _friend: Friend
    fileprivate var _date: Date
    fileprivate var _isSender: Bool
    
    init(mid: String, text: String, friend: Friend, date: Date, isSender: Bool = false) {
        _mid = mid
        _date = date
        _text = text
        _friend = friend
        _isSender = isSender
    }
    
    var mid: String {
        get {
            return _mid
        }
    }
    
    var text: String {
        get {
            return _text
        }
    }

    var friend: Friend {
        get {
            return _friend
        }
    }
    
    var date: Date {
        get {
            return _date
        }
    }
    
    var isSender: Bool {
        get {
            return _isSender
        }
    }
}
