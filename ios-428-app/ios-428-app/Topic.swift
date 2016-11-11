//
//  Topic.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Topic {
    
    fileprivate var _tid: String
    fileprivate var _prompt: String
    fileprivate var _imageName: String
    fileprivate var _description: String
    fileprivate var _date: Date
    fileprivate var _numMessages: Int
    fileprivate var _topicMessages: [TopicMessage] // Sorted where most recent topic message is at the top
    fileprivate var _latestMessageDate: Date
    fileprivate var _hasSeen: Bool
    
    // Computed variables
    var dateString: String?
    
    init(tid: String, prompt: String, imageName: String, description: String, date: Date = Date(), topicMessages: [TopicMessage] = [], latestMessageDate: Date = Date.distantPast, numMessages: Int = 0, hasSeen: Bool = true) {
        _tid = tid
        _prompt = prompt
        _imageName = imageName
        _description = description
        _date = date
        _numMessages = numMessages == 0 ? topicMessages.count : numMessages
        _topicMessages = topicMessages
        _latestMessageDate = latestMessageDate
        _hasSeen = hasSeen
        dateString = self.convertDateToString(date: date)
    }
    
    fileprivate func convertDateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    var tid: String {
        get {
            return _tid
        }
    }
    
    var prompt: String {
        get {
            return _prompt
        }
    }
    
    var imageName: String {
        get {
            return _imageName
        }
    }
    
    var description: String {
        get {
            return _description
        }
    }
    
    var date: Date {
        get {
            return _date
        }
    }
    
    var numMessages: Int {
        get {
            return _numMessages
        }
    }
    
    var topicMessages: [TopicMessage] {
        get {
            return _topicMessages
        }
    }
    
    var hasSeen: Bool {
        get {
            return _hasSeen
        }
    }
    
    var latestMessageDate: Date {
        get {
            return _latestMessageDate
        }
    }
}
