//
//  TopicMessage.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class TopicMessage {
    
    fileprivate var _tmid: String
    fileprivate var _parentTid: String
    fileprivate var _posterUid: String
    fileprivate var _posterDisciplineImageName: String
    fileprivate var _posterName: String
    fileprivate var _text: String
    fileprivate var _date: Date
    fileprivate var _isSender: Bool
    
    init(tmid: String, parentTid: String, posterUid: String, posterName: String, posterDisciplineImageName: String, text: String, date: Date = Date(), isSender: Bool = false) {
        _tmid = tmid
        _parentTid = parentTid
        _posterUid = posterUid
        _posterName = posterName
        _posterDisciplineImageName = posterDisciplineImageName
        _text = text
        _date = date
        _isSender = isSender
    }
    
    var tmid: String {
        get {
            return _tmid
        }
    }
    
    var parentTid: String {
        get {
            return _parentTid
        }
    }
    
    var posterUid: String {
        get {
            return _posterUid
        }
    }
    
    var posterName: String {
        get {
            return _posterName
        }
    }
    
    var posterDisciplineImageName: String {
        get {
            return _posterDisciplineImageName
        }
    }
    
    var text: String {
        get {
            return _text
        }
    }
    
    var date: Date {
        get {
            return _date
        }
    }
    
    var isSender: Bool {
        get {
            return _isSender
        }
    }
}
