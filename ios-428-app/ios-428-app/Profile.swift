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
    fileprivate var _disciplineImageName: String
    fileprivate var _profileImageName: String
    fileprivate var _disciplineBgName: String
    fileprivate var _age: Int
    fileprivate var _location: String // Country, City
    fileprivate var _org: String
    fileprivate var _school: String
    fileprivate var _discipline: String
    fileprivate var _tagline1: String // I am working on ...
    fileprivate var _tagline2: String // I want to eventually ...
    
    init(uid: String, name: String, disciplineImageName: String, profileImageName: String, disciplineBgName: String, age: Int, location: String, org: String, school: String, discipline: String, tagline1: String, tagline2: String) {
        _uid = uid
        _name = name
        _disciplineImageName = disciplineImageName
        _profileImageName = profileImageName
        _disciplineBgName = disciplineBgName
        _age = age
        _location = location
        _org = org
        _school = school
        _discipline = discipline
        _tagline1 = tagline1
        _tagline2 = tagline2
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
    
    var disciplineImageName: String {
        get {
            return _disciplineImageName
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
    
    var location: String {
        get {
            return _location
        }
    }
    
    var org: String {
        get {
            return _org
        }
    }
    
    var school: String {
        get {
            return _school
        }
    }
    
    var discipline: String {
        get {
            return _discipline
        }
    }
    
    var tagline1: String {
        get {
            return _tagline1
        }
    }
    
    var tagline2: String {
        get {
            return _tagline2
        }
    }
}
