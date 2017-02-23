//
//  Classroom.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Classroom {
    
    // These are read in from the start when viewing all classrooms
    fileprivate var _cid: String
    fileprivate var _title: String
    fileprivate var _timeReplied: Double // Unix time in MILLISECONDS used to sort classrooms - divide by 1000 before using this to init TimeInterval
    fileprivate var _hasUpdates: Bool // If true, there is a new message/question being posted that the user has not seen yet
    fileprivate var _questionNum: Int
    fileprivate var _questionText: String
    fileprivate var _imageName: String // Image name is the latest question's image url string
    fileprivate var _shareImageName: String // Latest question's share image url string (used for FB share on this question)
    
    // These are read in on opening the classroom
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
    
    
    init(cid: String, title: String, timeReplied: Double, hasUpdates: Bool, questionNum: Int, questionText: String, imageName: String, shareImageName: String, members: [Profile] = [], questions: [Question] = [], classroomMessages: [ClassroomMessage] = [], superlatives: [Superlative] = [], results: [Superlative] = [], superlativeType: SuperlativeType = SuperlativeType.NOTVOTED, hasSuperlatives: Bool = false, isVotingOngoing: Bool = false, didYouKnowId: String = "") {
        _cid = cid
        _title = title
        _timeReplied = timeReplied
        _hasUpdates = hasUpdates
        _questionNum = questionNum
        _questionText = questionText
        _imageName = imageName
        _shareImageName = shareImageName
        
        _members = members
        _questions = questions.sorted{$0.timestamp > $1.timestamp} // Most recent questions first
        _classroomMessages = classroomMessages
        _superlatives = superlatives
        _results = results
        _superlativeType = superlativeType
        _didYouKnowId = didYouKnowId
        _hasSuperlatives = hasSuperlatives
        _isVotingOngoing = isVotingOngoing
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
    
    var timeReplied: Double {
        get {
            return _timeReplied
        }
    }
    
    var members: [Profile] {
        get {
            return _members
        }
        set(memb) {
            _members = memb
        }
    }
    
    var questions: [Question] {
        get {
            return _questions
        }
        set(qs) {
            _questions = qs.sorted{$0.timestamp > $1.timestamp} // Most recent questions first
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
        set (did) {
            _didYouKnowId = did
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
    
    var questionText: String {
        get {
            return _questionText
        }
    }
    
    var imageName: String {
        get {
            return _imageName
        }
    }
    
    var shareImageName: String {
        get {
            return _shareImageName
        }
    }
}
