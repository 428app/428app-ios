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
        
        let meController = MeController()
        let meNavController = CustomNavigationController(rootViewController: meController)
        meNavController.tabBarItem.title = "Me"
        meNavController.tabBarItem.image = #imageLiteral(resourceName: "me-U-2x")
        meNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "me-F-2x")
        
        let classroomsController = ClassroomsController()
        let classroomsNavController = CustomNavigationController(rootViewController: classroomsController)
        classroomsNavController.tabBarItem.title = "Classrooms"
        classroomsNavController.tabBarItem.image = #imageLiteral(resourceName: "classrooms-U-2x")
        classroomsNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "classrooms-F-2x")
        
        let layout = UICollectionViewFlowLayout()
        let inboxController = InboxController(collectionViewLayout: layout)
        let inboxNavController = CustomNavigationController(rootViewController: inboxController)
        inboxNavController.tabBarItem.title = "Inbox"
        inboxNavController.tabBarItem.image = #imageLiteral(resourceName: "inbox-U-2x")
        inboxNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "inbox-F-2x")
        
        // NOTE: Changing this order will break the remote notification logic in AppDelegate
        viewControllers = [meNavController, classroomsNavController, inboxNavController]
    }
}
