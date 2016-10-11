//
//  NavigationController.swift
//  ios-428
//
//  Created by Leonard Loo on 10/5/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: GREEN_UICOLOR,
                                                  NSFontAttributeName: FONT_HEAVY_LARGE]
        self.navigationBar.tintColor = GREEN_UICOLOR
    }
}
