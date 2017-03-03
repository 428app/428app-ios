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
                                                  NSFontAttributeName: FONT_HEAVY_XLARGE]
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.backgroundColor = GREEN_UICOLOR
        self.navigationBar.barTintColor = GREEN_UICOLOR
//        self.navigationBar.isTranslucent = false
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: FONT_MEDIUM_LARGE], for: .normal)
    }
}
