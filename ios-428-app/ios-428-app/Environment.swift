//
//  Variables.swift
//  ios-428-app
//
//  NOTE: This is an important file containing all the switches that manipulate app state.
//  Created by Leonard Loo on 10/22/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

// After user completes intro flow and dismisses, the user goes back to LoginController
// LoginController will immediately segue to CustomTabBar if this value is true
var justFinishedIntro = false

// Shows IntroController if it is first time user, otherwise just progress straight to CustomTabBar
var isFirstTimeUser = true
