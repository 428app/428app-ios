//
//  ClassroomMessage.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class ClassroomMessage {
    
    fileprivate var _mid: String
    fileprivate var _parentCid: String
    fileprivate var _posterUid: String
    fileprivate var _text: String
    fileprivate var _date: Date // Date of message posted
    fileprivate var _isSentByYou: Bool
    fileprivate var _isSentBy428: Bool
    
    init(mid: String, parentCid: String, posterUid: String, text: String, date: Date = Date(), isSentByYou: Bool = false) {
        _mid = mid
        _parentCid = parentCid
        _posterUid = posterUid
        _text = text
        _date = date
        _isSentByYou = isSentByYou
        _isSentBy428 = posterUid == "428" // Classroom messages sent by server has poster as 428
    }
    
    var mid: String {
        get {
            return _mid
        }
    }
    
    var parentCid: String {
        get {
            return _parentCid
        }
    }
    
    var posterUid: String {
        get {
            return _posterUid
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
    
    var isSentByYou: Bool {
        get {
            return _isSentByYou
        }
    }
    
    var isSentBy428: Bool {
        get {
            return _isSentBy428
        }
    }
}
