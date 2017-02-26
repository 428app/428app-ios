//
//  Enums.swift
//  ios-428-app
//
//  Created by Leonard Loo on 11/17/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation


enum TokenType: String {
    case INBOX = "inbox", CLASSROOM = "classroom", ALERT = "alert"
}

enum SuperlativeType: Int {
    case NOTVOTED = 0, VOTED, SHARED
}

enum QuestionVoteType: Int {
    case DISLIKED = -1, NEUTRAL = 0, LIKED = 1
}
