//
//  AnalyticsConstants.swift
//  ios-428-app
//
//  Created by Leonard Loo on 2/17/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import Firebase

// Me page
let kEventViewPhotoOnMe = "view_photo_me"

// Me + View profile page
let kEventClickOnPlaygroupIcon = "click_playgroup_icon"

// View profile page
let kEventViewPhotoOnProfile = "view_photo_profile"
let kEventDismissProfileClicked = "dismiss_profile"
let kEventDismissProfileSlide = "dismiss_profile_slide"

// Inbox page
let kEventViewProfileFromNav = "view_profile_from_inbox_nav"
let kEventViewProfileFromPlaceholder = "view_profile_from_placeholder"
let kEventViewProfileFromThumbnail = "view_profile_from_thumbnail"

// Playgroups page
let kEventViewQuestion = "view_question"
let kEventMoreNavClicked = "click_more_nav"

// Settings page
let kEventVisitWebsite = "visit_website"
let kEventVisitFacebook = "visit_facebook"
let kEventRateUs = "rate_us"
let kEventVisitPrivacyPolicy = "visit_privacy_policy"

// Share hooks
let kEventOpenShareQuestion = "openShareQuestion"
let kEventSuccessShareQuestion = "successShareQuestion"
let kEventOpenTweetQuestion = "openTweetQuestion"
let kEventSuccessTweetQuestion = "successTweetQuestion"
let kEventOpenShareAnswer = "openShareAnswer"
let kEventSuccessShareAnswer = "successShareAnswer"
let kEventSuccessShareDidYouKnow = "successShareDidYouKnow"

func logAnalyticsEvent(key: String, params: [String: NSObject] = [:]) { // We're not passing over any params, just logging the event
    FIRAnalytics.logEvent(withName: key, parameters: params)
}
