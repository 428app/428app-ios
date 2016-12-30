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
    fileprivate var _ratings: [Rating]
    fileprivate var _hasRated: Bool
    fileprivate var _hasUpdates: Bool
    
    // Computed variables from questions array
    var _questionNum: Int
    var _imageName: String
    
    init(cid: String, title: String, timeCreated: Double, members: [Profile], questions: [Question], classroomMessages: [ClassroomMessage] = [], ratings: [Rating] = [], hasRated: Bool = false, hasUpdates: Bool = false) {
        _cid = cid
        _title = title
        _timeCreated = timeCreated
        _members = members
        _questions = questions.sorted{$0.timestamp > $1.timestamp} // Most recent questions first
        _classroomMessages = classroomMessages
        _ratings = ratings
        _hasRated = hasRated
        _hasUpdates = hasUpdates
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
    
    var ratings: [Rating] {
        get {
            return _ratings
        }
    }
    
    var hasRated: Bool {
        get {
            return _hasRated
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
