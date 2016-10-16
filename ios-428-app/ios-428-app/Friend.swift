//
//  Friend.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/15/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Friend {
    
    fileprivate var _uid: String
    fileprivate var _name: String
    fileprivate var _profileImageName: String
    fileprivate var _disciplineImageName: String // Packaged in the app's assets
    fileprivate var _messages = [Message]()
    
    init(uid: String, name: String, profileImageName: String, disciplineImageName: String, messages: [Message] = [Message]()) {
        _uid = uid
        _name = name
        _profileImageName = profileImageName
        _disciplineImageName = disciplineImageName
        _messages = messages
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
}
