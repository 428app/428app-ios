//
//  Enums.swift
//  ios-428-app
//
//  Created by Leonard Loo on 11/17/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation


enum TokenType: String {
    case INBOX = "inbox", CLASSROOM = "classroom"
}

enum RatingType: Int {
    case NOTRATED = 0, RATED, SHARED
}
