//
//  Connection.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/15/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Connection {
    
    fileprivate var _uid: String
    fileprivate var _name: String
    fileprivate var _profileImageName: String
    fileprivate var _disciplineImageName: String // Packaged in the app's assets
    fileprivate var _messages = [Message]() // Not loaded off the start, only loaded when user clicks on chat
    fileprivate var _dateMatched: Date
    fileprivate var _recentMessage: String
    
    init(uid: String, name: String, profileImageName: String, disciplineImageName: String, messages: [Message] = [Message](), dateMatched: Date = Date(), recentMessage: String = "") {
        _uid = uid
        _name = name
        _profileImageName = profileImageName
        _disciplineImageName = disciplineImageName
        _messages = messages
        _dateMatched = dateMatched
        _recentMessage = recentMessage
    }
    
    var uid: String {
        get {
            return _uid
        }
    }
    
    var name: String {
        get {
            return _name
        }
    }
    
    var profileImageName: String {
        get {
            return _profileImageName
        }
    }
    
    var disciplineImageName: String {
        get {
            return _disciplineImageName
        }
    }
    
    var messages: [Message] {
        get {
            return _messages
        }
    }
    
    func addMessage(message: Message) {
        _messages.append(message)
    }
    
    var dateMatched: Date {
        get {
            return _dateMatched
        }
    }
    
    var recentMessage: String {
        get {
            return _recentMessage
        }
    }
}
