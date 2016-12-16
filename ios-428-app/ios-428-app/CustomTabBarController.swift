//
//  CustomTabBarController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

// NOTE: Please DO NOT change this file

class CustomTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false
        
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGray.withAlphaComponent(0.8), NSFontAttributeName: FONT_MEDIUM_SMALL], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: GREEN_UICOLOR, NSFontAttributeName: FONT_MEDIUM_SMALL], for: .selected)
        let layout = UICollectionViewFlowLayout()
        let connectionsController = ConnectionsController(collectionViewLayout: layout)
        let connectionsNavController = CustomNavigationController(rootViewController: connectionsController)
        connectionsNavController.tabBarItem.title = "Messages"
        
        connectionsNavController.tabBarItem.image = #imageLiteral(resourceName: "connections-U")
        connectionsNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "connections-F")
        
        let topicsController = TopicsController()
        let topicsNavController = CustomNavigationController(rootViewController: topicsController)
        topicsNavController.tabBarItem.title = "Classrooms"
        topicsNavController.tabBarItem.image = #imageLiteral(resourceName: "topics-U")
        topicsNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "topics-F")
        
        let settingsController = SettingsController()
        let settingsNavController = CustomNavigationController(rootViewController: settingsController)
        settingsNavController.tabBarItem.title = "Profile"
        settingsNavController.tabBarItem.image = #imageLiteral(resourceName: "settings-U")
        settingsNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "settings-F")
        
        // NOTE: Changing this order will break the remote notification logic in AppDelegate
        viewControllers = [connectionsNavController, topicsNavController, settingsNavController]
    }
    
    
}
