//
//  Profile.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/16/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Profile {
    
    fileprivate var _uid: String
    fileprivate var _name: String
    fileprivate var _profileImageName: String
    fileprivate var _disciplineBgName: String
    fileprivate var _age: Int
    fileprivate var _distanceAway: Int
    fileprivate var _org: String
    fileprivate var _discipline: String
    
    init(uid: String, name: String, profileImageName: String, disciplineBgName: String, age: Int, distanceAway: Int, org: String, discipline: String) {
        _uid = uid
        _name = name
        _profileImageName = profileImageName
        _disciplineBgName = disciplineBgName
        _age = age
        _distanceAway = distanceAway
        _org = org
        _discipline = discipline
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
    
    var disciplineBgName: String {
        get {
            return _disciplineBgName
        }
    }
    
    var age: Int {
        get {
            return _age
        }
    }
    
    var distanceAway: Int {
        get {
            return _distanceAway
        }
    }
    
    var org: String {
        get {
            return _org
        }
    }
    
    var discipline: String {
        get {
            return _discipline
        }
    }
}
