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
    fileprivate var _discipline: String
    fileprivate var _location: String // Country, City
    fileprivate var _school: String
    fileprivate var _org: String
    fileprivate var _tagline: String // My childhood ambition is
    fileprivate var _playgroups: [String]
    fileprivate var _age: Int?
    
    // Calculated variable
    fileprivate var _disciplineIcon: String
    fileprivate var _playgroupIcons: [String]
    
    init(uid: String, name: String, profileImageName: String, discipline: String, location: String, school: String, org: String, tagline: String, playgroups: [String], age: Int?) {
        _uid = uid
        _name = name
        _profileImageName = profileImageName
        _discipline = discipline
        _location = location
        _school = school
        _org = org
        _tagline = tagline
        _playgroups = playgroups
        _age = age
        _disciplineIcon = getDisciplineIcon(discipline: _discipline)
        _playgroupIcons = [String]()
        for c in playgroups {
            _playgroupIcons.append(getDisciplineIcon(discipline: c))
        }
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
    
    var discipline: String {
        get {
            return _discipline
        }
        set(d) {
            _discipline = d
            _disciplineIcon = getDisciplineIcon(discipline: d)
        }
    }
    
    var age: Int? {
        get {
            return _age
        }
    }
    
    var location: String {
        get {
            return _location
        }
    }
    
    var school: String {
        get {
            return _school
        }
        set(s) {
            _school = s
        }
    }
    
    var org: String {
        get {
            return _org
        }
        set(o) {
            _org = o
        }
    }
    
    var tagline: String {
        get {
            return _tagline
        }
        set(t) {
            _tagline = t
        }
    }
    
    var disciplineIcon: String {
        get {
            return _disciplineIcon
        }
    }
    
    var playgroupIcons: [String] {
        get {
            return _playgroupIcons
        }
    }
}
