//
//  Inbox.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/15/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Inbox {
    
    fileprivate var _uid: String
    fileprivate var _name: String
    fileprivate var _profileImageName: String
    fileprivate var _discipline: String
    fileprivate var _hasNewMessages: Bool
    
    // NOTE: Most recent message is on top of messages
    fileprivate var _messages = [InboxMessage]() // Not loaded off the start, only loaded when user clicks on chat
    fileprivate var _dateMatched: String
    fileprivate var _disciplineImageName: String // Packaged in the app's assets
    
    init(uid: String, name: String, profileImageName: String, discipline: String, messages: [InboxMessage] = [InboxMessage](), dateMatched: String = "", hasNewMessages: Bool = false) {
        _uid = uid
        _name = name
        _profileImageName = profileImageName
        _discipline = discipline
        _hasNewMessages = hasNewMessages
        _messages = messages
        _dateMatched = dateMatched
        _disciplineImageName = getDisciplineIcon(discipline: discipline)
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
    
    var discipline: String {
        get {
            return _discipline
        }
    }
    
    var disciplineImageName: String {
        get {
            return _disciplineImageName
        }
    }
    
    var hasNewMessages: Bool {
        get {
            return _hasNewMessages
        }
        set(hasNew) {
            _hasNewMessages = hasNew
        }
    }
    
    var messages: [InboxMessage] {
        get {
            return _messages
        }
    }
    
    func addMessage(message: InboxMessage) {
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
