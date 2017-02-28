//
//  Playgroup.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Playgroup {
    
    // These are read in from the start when viewing all playgroups
    fileprivate var _pid: String
    fileprivate var _title: String
    fileprivate var _timeReplied: Double // Unix time in MILLISECONDS used to sort playgroups - divide by 1000 before using this to init TimeInterval
    fileprivate var _hasUpdates: Bool // If true, there is a new message/question being posted that the user has not seen yet
    fileprivate var _questionNum: Int
    fileprivate var _questionText: String
    fileprivate var _imageName: String // Image name is the latest question's image url string
    fileprivate var _shareImageName: String // Latest question's share image url string (used for FB share on this question)
    
    // These are read in on opening the playgroup
    fileprivate var _members: [Profile] // Used to display members and their profiles
    fileprivate var _questions: [Question] // Get question number from this
    fileprivate var _playgroupMessages: [PlaygroupMessage]
    
    /** Superlatives **/
    fileprivate var _hasSuperlatives: Bool // If true, enabled superlatives button from Playgroup Chat
    fileprivate var _isVotingOngoing: Bool // If true, there are only partial results and not everyone has voted yet
    fileprivate var _superlatives: [Superlative] // Your superlatives of your playpeers
    fileprivate var _results: [Superlative] // The overall superlatives of all playpeers downloaded from server
    fileprivate var _superlativeType: SuperlativeType
    fileprivate var _didYouKnowId: String
    
    
    init(pid: String, title: String = "", timeReplied: Double = 0, hasUpdates: Bool = true, questionNum: Int = 1, questionText: String = "", imageName: String = "", shareImageName: String = "", members: [Profile] = [], questions: [Question] = [], playgroupMessages: [PlaygroupMessage] = [], superlatives: [Superlative] = [], results: [Superlative] = [], superlativeType: SuperlativeType = SuperlativeType.NOTVOTED, hasSuperlatives: Bool = false, isVotingOngoing: Bool = false, didYouKnowId: String = "") {
        _pid = pid
        _title = title
        _timeReplied = timeReplied
        _hasUpdates = hasUpdates
        _questionNum = questionNum
        _questionText = questionText
        _imageName = imageName
        _shareImageName = shareImageName
        
        _members = members
        _questions = questions.sorted{$0.timestamp > $1.timestamp} // Most recent questions first
        _playgroupMessages = playgroupMessages
        _superlatives = superlatives
        _results = results
        _superlativeType = superlativeType
        _didYouKnowId = didYouKnowId
        _hasSuperlatives = hasSuperlatives
        _isVotingOngoing = isVotingOngoing
    }
    
    var pid: String {
        get {
            return _pid
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
    
    var playgroupMessages: [PlaygroupMessage] {
        get {
            return _playgroupMessages
        }
    }
    
    func addMessage(message: PlaygroupMessage) {
        _playgroupMessages.append(message)
    }
    
    func clearMessages() {
        _playgroupMessages = []
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
