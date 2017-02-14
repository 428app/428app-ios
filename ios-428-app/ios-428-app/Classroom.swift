//
//  Classroom.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Classroom {
    
    fileprivate var _cid: String
    fileprivate var _title: String
    fileprivate var _timeCreated: Double // Unix time used to sort classrooms
    fileprivate var _members: [Profile] // Used to display members and their profiles
    fileprivate var _questions: [Question] // Get question number from this
    fileprivate var _classroomMessages: [ClassroomMessage]
    
    /** Superlatives **/
    fileprivate var _hasSuperlatives: Bool // If true, enabled superlatives button from Classroom Chat
    fileprivate var _isVotingOngoing: Bool // If true, there are only partial results and not everyone has voted yet
    fileprivate var _superlatives: [Superlative] // Your superlatives of your classmates
    fileprivate var _results: [Superlative] // The overall superlatives of all classmates downloaded from server
    fileprivate var _superlativeType: SuperlativeType
    fileprivate var _didYouKnowId: String
    
    fileprivate var _hasUpdates: Bool // If true, there is a new message/question being posted that the user has not seen yet
    
    // Computed variables from questions array
    var _questionNum: Int
    var _imageName: String
    
    init(cid: String, title: String, timeCreated: Double, members: [Profile], questions: [Question], classroomMessages: [ClassroomMessage] = [], superlatives: [Superlative] = [], results: [Superlative] = [], superlativeType: SuperlativeType = SuperlativeType.NOTVOTED, hasUpdates: Bool = false, hasSuperlatives: Bool = false, isVotingOngoing: Bool = false, didYouKnowId: String = "") {
        _cid = cid
        _title = title
        _timeCreated = timeCreated
        _members = members
        _questions = questions.sorted{$0.timestamp > $1.timestamp} // Most recent questions first
        _classroomMessages = classroomMessages
        _superlatives = superlatives
        _results = results
        _superlativeType = superlativeType
        _didYouKnowId = didYouKnowId
        _hasUpdates = hasUpdates
        _hasSuperlatives = hasSuperlatives
        _isVotingOngoing = isVotingOngoing
        // Compute question num and imageName to display from questions
        _questionNum = questions.count
        _imageName = _questions.count == 0 ? "" : _questions[0].imageName // Fail silently if no questions provided in init
    }
    
    var cid: String {
        get {
            return _cid
        }
    }
    
    var title: String {
        get {
            return _title
        }
    }
    
    var timeCreated: Double {
        get {
            return _timeCreated
        }
    }
    
    var members: [Profile] {
        get {
            return _members
        }
    }
    
    var questions: [Question] {
        get {
            return _questions
        }
    }
    
    var classroomMessages: [ClassroomMessage] {
        get {
            return _classroomMessages
        }
    }
    
    func addMessage(message: ClassroomMessage) {
        _classroomMessages.append(message)
    }
    
    func clearMessages() {
        _classroomMessages = []
    }
    
    var hasSuperlatives: Bool {
        get {
            return _hasSuperlatives
        }
        set(hasSup) {
            _hasSuperlatives = hasSup
        }
    }
    
    var superlatives: [Superlative] {
        get {
            return _superlatives
        }
        set(sups) {
            _superlatives = sups
        }
    }
    
    var results: [Superlative] {
        get {
            return _results
        }
        set(res) {
            _results = res
        }
    }
    
    var superlativeType: SuperlativeType {
        get {
            return _superlativeType
        }
        set(supType) {
            _superlativeType = supType
        }
    }
    
    var didYouKnowId: String {
        get {
            return _didYouKnowId
        }
    }
    
    var isVotingOngoing: Bool {
        get {
            return _isVotingOngoing
        }
        set(ongo) {
            _isVotingOngoing = ongo
        }
    }
    
    var hasUpdates: Bool {
        get {
            return _hasUpdates
        }
    }
    
    var questionNum: Int {
        get {
            return _questionNum
        }
    }
    
    var imageName: String {
        get {
            return _imageName
        }
    }
}
