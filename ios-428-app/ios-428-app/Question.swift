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
    fileprivate var _timestamp: Double
    fileprivate var _imageName: String
    fileprivate var _question: String
    fileprivate var _answer: String
    fileprivate var _isVideo: Bool
    
    init(qid: String, timestamp: Double, imageName: String, question: String, answer: String) {
        _qid = qid
        _timestamp = timestamp
        _imageName = imageName
        _question = question
        _answer = answer
        _isVideo = answer.hasPrefix("https://www.youtube.com/")
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
    }
    
    var question: String {
        get {
            return _question
        }
    }
    
    var answer: String {
        get {
            return _answer
        }
    }
    
    var isVideo: Bool {
        get {
            return _isVideo
        }
    }
}
