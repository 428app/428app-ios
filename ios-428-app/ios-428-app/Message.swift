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
    fileprivate var _connection: Connection
    fileprivate var _date: Date
    fileprivate var _isSender: Bool // Is sent by you
    fileprivate var _isSeen: Bool
    
    init(mid: String, text: String, connection: Connection, date: Date, isSender: Bool = false, isSeen: Bool = true) {
        _mid = mid
        _date = date
        _text = text
        _connection = connection
        _isSender = isSender
        _isSeen = isSeen
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

    var connection: Connection {
        get {
            return _connection
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
    
    var isSeen: Bool {
        get {
            return _isSeen
        }
    }
}
