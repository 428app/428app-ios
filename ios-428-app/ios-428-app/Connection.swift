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
    
    // NOTE: Most recent message is on top of messages
    fileprivate var _messages = [Message]() // Not loaded off the start, only loaded when user clicks on chat
    fileprivate var _dateMatched: String
    
    init(uid: String, name: String, profileImageName: String, disciplineImageName: String, messages: [Message] = [Message](), dateMatched: String = "") {
        _uid = uid
        _name = name
        _profileImageName = profileImageName
        _disciplineImageName = disciplineImageName
        _messages = messages
        _dateMatched = dateMatched
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
    
    func clearMessages() {
        _messages = []
    }
    
    var dateMatched: String {
        get {
            return _dateMatched
        }
        set(date) {
            _dateMatched = date
        }
        
    }

}
