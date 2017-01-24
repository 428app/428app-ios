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
    fileprivate var _age: Int
    fileprivate var _location: String // Country, City
    fileprivate var _school: String
    fileprivate var _org: String
    fileprivate var _tagline: String // What I do at 4:28pm
    fileprivate var _badges: [String]
    fileprivate var _classrooms: [String]
    
    // Calculated variable
    fileprivate var _disciplineIcon: String
    fileprivate var _classroomIcons: [String]
    fileprivate var _badgeIcons: [String]
    
    init(uid: String, name: String, profileImageName: String, discipline: String, age: Int, location: String, school: String, org: String, tagline: String, badges: [String], classrooms: [String]) {
        _uid = uid
        _name = name
        _profileImageName = profileImageName
        _discipline = discipline
        _age = age
        _location = location
        _school = school
        _org = org
        _tagline = tagline
        _badges = badges
        _classrooms = classrooms
        _disciplineIcon = getDisciplineIcon(discipline: _discipline)
        _classroomIcons = [String]()
        for c in classrooms {
            _classroomIcons.append(getDisciplineIcon(discipline: c))
        }
        
        // TODO: Convert badge icons
        _badgeIcons = [String]()
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
    
    var classroomIcons: [String] {
        get {
            return _classroomIcons
        }
    }
    
    var badgeIcons: [String] {
        get {
            return _badgeIcons
        }
    }
}
