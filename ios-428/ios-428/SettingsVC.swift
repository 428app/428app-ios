//
//  SettingsVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/5/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNavController()
    }

    private func initNavController() {
        self.navigationItem.title = "Settings"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Dismiss"), style: .plain, target: self, action: #selector(SettingsVC.backToMatches))
    }
    
    func backToMatches() {
        self.dismiss(animated: true, completion: nil)
    }

}
