//
//  Variables.swift
//  ios-428-app
//
//  NOTE: This is an important file containing all the switches that manipulate app state, and side effects that we will use.
//  Created by Leonard Loo on 10/22/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

// After user completes intro flow and dismisses, the user goes back to LoginController
// LoginController will immediately segue to CustomTabBar if this value is true
var justFinishedIntro = false
var isFirstTimeUser = false

// Used to display tutorial alert on Playgroups tab
var notCheckedOutTutorial = false

// Used to sound smart once per app launch
var hasSoundSmartAlert = true

// Side effect to see if InboxController should immediately bring up a private chat with this inbox upon loading
// The private chat comes from clicking Send Message from viewing another user's profile
var inboxToOpen: Inbox?
