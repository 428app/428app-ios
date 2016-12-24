//
//  ConnectionMessage.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/15/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class PrivateMessage {

    fileprivate var _mid: String
    fileprivate var _text: String
    fileprivate var _privateChat: PrivateChat
    fileprivate var _date: Date
    fileprivate var _isSentByYou: Bool // True if is sent by you
//    fileprivate var _hasSeen: Bool
    
    init(mid: String, text: String, privateChat: PrivateChat, date: Date, isSentByYou: Bool = false) {
        _mid = mid
        _date = date
        _text = text
        _privateChat = privateChat
        _isSentByYou = isSentByYou
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

    var privateChat: PrivateChat {
        get {
            return _privateChat
        }
    }
    
    var date: Date {
        get {
            return _date
        }
    }
    
    var isSentByYou: Bool {
        get {
            return _isSentByYou
        }
    }
}
