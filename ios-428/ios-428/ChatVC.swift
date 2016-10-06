//
//  ChatVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class ChatVC: UIViewController {
    
    var match: Match!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNavController()
    }

    private func initNavController() {
        self.navigationItem.title = match.username
    }
    
}
