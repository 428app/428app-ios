//
//  Question.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/29/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Question {
    
    fileprivate var _qid: String
    fileprivate var _timestamp: Double // UNIX Time in Milliseconds
    fileprivate var _imageName: String
    fileprivate var _shareImageName: String
    fileprivate var _question: String
    fileprivate var _answer: String
    fileprivate var _isVideo: Bool
    fileprivate var _userVote: QuestionVoteType
    
    // Qids and timestamps compulsory, because they identify a question uniquely to a classroom
    init(qid: String, timestamp: Double, imageName: String = "", shareImageName: String = "", question: String = "", answer: String = "", userVote: QuestionVoteType = .NEUTRAL) {
        _qid = qid
        _timestamp = timestamp
        _imageName = imageName
        _shareImageName = shareImageName
        _question = question
        _answer = answer
        _isVideo = answer.hasPrefix("https://www.youtube.com/") // If answer starts with a youtube link, it is a video
        _userVote = userVote
    }
    
    var qid: String {
        get {
            return _qid
        }
    }
    
    var timestamp: Double {
        get {
            return _timestamp
        }
    }
    
    var imageName: String {
        get {
            return _imageName
        }
        set(imgName) {
            _imageName = imgName
        }
    }
    
    var shareImageName: String {
        get {
            return _shareImageName
        }
        set(imgName) {
            _shareImageName = imgName
        }
    }
    
    var question: String {
        get {
            return _question
        }
        set(q) {
            _question = q
        }
    }
    
    var answer: String {
        get {
            return _answer
        }
        set(ans) {
            _answer = ans
            _isVideo = ans.hasPrefix("https://www.youtube.com/")
        }
    }
    
    var isVideo: Bool {
        get {
            return _isVideo
        }
    }
    
    var userVote: QuestionVoteType {
        get {
            return _userVote
        }
        set(vote) {
            _userVote = vote
        }
    }
}
