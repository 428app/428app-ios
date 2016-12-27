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
        let privateChatController = PrivateChatController(collectionViewLayout: layout)
        let privateChatNavController = CustomNavigationController(rootViewController: privateChatController)
        privateChatNavController.tabBarItem.title = "Messages"
        
        privateChatNavController.tabBarItem.image = #imageLiteral(resourceName: "connections-U")
        privateChatNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "connections-F")
        
        let topicsController = TopicsController()
        let topicsNavController = CustomNavigationController(rootViewController: topicsController)
        topicsNavController.tabBarItem.title = "Classrooms"
        topicsNavController.tabBarItem.image = #imageLiteral(resourceName: "topics-U")
        topicsNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "topics-F")
        
        let meController = MeController()
        let meNavController = CustomNavigationController(rootViewController: meController)
        meNavController.tabBarItem.title = "Me"
        meNavController.tabBarItem.image = #imageLiteral(resourceName: "me-U")
        meNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "me-F")
        
        // NOTE: Changing this order will break the remote notification logic in AppDelegate
        viewControllers = [meNavController, topicsNavController, privateChatNavController]
    }
}
