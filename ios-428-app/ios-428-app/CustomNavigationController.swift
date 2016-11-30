//
//  CustomNavigationController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class CustomNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white,
                                                  NSFontAttributeName: FONT_HEAVY_LARGE]
//        self.navigationBar.tintColor = GREEN_UICOLOR
//        self.navigationBar.backgroundColor = UIColor.white
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.backgroundColor = GREEN_UICOLOR
        self.navigationBar.barTintColor = GREEN_UICOLOR
        
    }
}
