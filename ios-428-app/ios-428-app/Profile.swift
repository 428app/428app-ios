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
    fileprivate var _coverImageName: String
    fileprivate var _profileImageName: String
    fileprivate var _age: Int
    fileprivate var _location: String // Country, City
    fileprivate var _org: String
    fileprivate var _school: String
    fileprivate var _discipline: String
    fileprivate var _tagline1: String // I am working on ...
    fileprivate var _tagline2: String // I want to eventually ...
    
    // Calculated variable
    fileprivate var _disciplineIcon: String
    
    init(uid: String, name: String, coverImageName: String, profileImageName: String, age: Int, location: String, org: String, school: String, discipline: String, tagline1: String, tagline2: String) {
        _uid = uid
        _name = name
        _coverImageName = coverImageName
        _profileImageName = profileImageName
        _age = age
        _location = location
        _org = org
        _school = school
        _tagline1 = tagline1
        _tagline2 = tagline2
        _discipline = discipline
        _disciplineIcon = "business" // TODO: Map discipline string to local icon
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
    
    var coverImageName: String {
        get {
            return _coverImageName
        }
    }
    
    var profileImageName: String {
        get {
            return _profileImageName
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
    
    var disciplineIcon: String {
        get {
            return _disciplineIcon
        }
    }
}
