//
//  Constants.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

// Notifications
let NOTIF_EXPANDCHATCELL = NSNotification.Name.init(rawValue: "expandChatCell")
let NOTIF_EXPANDTOPICCELL = NSNotification.Name.init(rawValue: "expandClassroomCell")
let NOTIF_CHANGESETTING = NSNotification.Name.init(rawValue: "changeSetting")
let NOTIF_EDITPROFILE = NSNotification.Name.init(rawValue: "editProfile")
let NOTIF_OPENPROFILE = NSNotification.Name.init(rawValue: "openProfile")
let NOTIF_MYPROFILEDOWNLOADED = NSNotification.Name.init(rawValue: "myProfileDownloaded")
let NOTIF_MYPROFILEPICDOWNLOADED = NSNotification.Name.init(rawValue: "myProfilePicDownloaded")
let NOTIF_PROFILEICONTAPPED = NSNotification.Name.init(rawValue: "profileIconTapped")

// Colors
let GRAY_UICOLOR: UIColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
let GREEN_UICOLOR: UIColor = UIColor(red: 54/255.0, green: 208/255.0, blue: 112/255.0, alpha: 1.0) // #36d070
let FB_BLUE_UICOLOR: UIColor = UIColor(red: 59/255.0, green: 89/255.0, blue: 152/255.0, alpha: 1.0) // #3b5998
let RED_UICOLOR: UIColor = UIColor(red: 217/255.0, green: 71/255.0, blue: 129/255.0, alpha: 1.0) // #d94781

// Fonts
let FONT_LIGHT_SMALL = UIFont(name: "AvenirLTStd-Light", size: 14)!
let FONT_LIGHT_MID = UIFont(name: "AvenirLTStd-Light", size: 16)!
let FONT_LIGHT_LARGE = UIFont(name: "AvenirLTStd-Light", size: 18)!
let FONT_MEDIUM_SMALL = UIFont(name: "AvenirLTStd-Medium", size: 14)!
let FONT_MEDIUM_SMALLMID = UIFont(name: "AvenirLTStd-Medium", size: 15)!
let FONT_MEDIUM_MID = UIFont(name: "AvenirLTStd-Medium", size: 16)!
let FONT_MEDIUM_LARGE = UIFont(name: "AvenirLTStd-Medium", size: 18)!
let FONT_MEDIUM_XLARGE = UIFont(name: "AvenirLTStd-Medium", size: 23)!
let FONT_MEDIUM_XXLARGE = UIFont(name: "AvenirLTStd-Medium", size: 30)!
let FONT_HEAVY_SMALL = UIFont(name: "AvenirLTStd-Heavy", size: 14)!
let FONT_HEAVY_MID = UIFont(name: "AvenirLTStd-Heavy", size: 16)!
let FONT_HEAVY_LARGE = UIFont(name: "AvenirLTStd-Heavy", size: 18)!
let FONT_HEAVY_XLARGE = UIFont(name: "AvenirLTStd-Heavy", size: 20)!
let FONT_HEAVY_XXLARGE = UIFont(name: "AvenirLTStd-Heavy", size: 30)!
