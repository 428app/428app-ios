//
//  CustomTabBarController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class CustomTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: GRAY_UICOLOR, NSFontAttributeName: FONT_HEAVY_SMALL], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: GREEN_UICOLOR, NSFontAttributeName: FONT_HEAVY_SMALL], for: .selected)
        let layout = UICollectionViewFlowLayout()
        let friendsController = FriendsController(collectionViewLayout: layout)
        let connectionsNavController = CustomNavigationController(rootViewController: friendsController)
        connectionsNavController.tabBarItem.title = "Connections"
        connectionsNavController.tabBarItem.image = #imageLiteral(resourceName: "chat-U")
        connectionsNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "chat-F")
        
        let topicController = UIViewController()
        let topicNavController = CustomNavigationController(rootViewController: topicController)
        topicNavController.tabBarItem.title = "Topics"
        topicNavController.tabBarItem.image = #imageLiteral(resourceName: "topic-U")
        topicNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "topic-F")
        
        let profileController = UIViewController()
        let profileNavController = CustomNavigationController(rootViewController: profileController)
        profileNavController.tabBarItem.title = "Profile"
        profileNavController.tabBarItem.image = #imageLiteral(resourceName: "profile-U")
        profileNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "profile-F")
        
        viewControllers = [connectionsNavController, topicNavController, profileNavController]
    }
    
    
}
