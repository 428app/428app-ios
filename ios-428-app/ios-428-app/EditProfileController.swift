//
//  EditProfileController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/18/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class EditProfileController: UIViewController {
    
    var profile: Profile! // Pull this profile from server
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Edit Profile"
        self.view.backgroundColor = UIColor.white
        self.loadProfileData()
    }
    
    func loadProfileData() {
        
    }
    
    
}
