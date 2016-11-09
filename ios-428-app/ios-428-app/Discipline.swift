//
//  Discipline.swift
//  ios-428-app
//
//  Created by Leonard Loo on 11/8/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

// TODO: Add in the full list of disciplines here
let DISCIPLINE_OPTIONS = ["Business", "Computer Science", "Biology", "East Asian Studies", "Physics", "Electrical Engineering"]
// Maps in sorted order
let DISCIPLINE_ICONS = ["business", "computer", "biology", "eastasian", "physics", "electricengineering"]
func getDisciplineIconForDiscipline(discipline: String) -> String {
    let ind = DISCIPLINE_OPTIONS.index(of: discipline)
    if ind != nil && ind! > 0 && ind! < DISCIPLINE_ICONS.count {
        return DISCIPLINE_ICONS[ind!]
    }
    return "business" // TODO: Set a default discipline here
}
