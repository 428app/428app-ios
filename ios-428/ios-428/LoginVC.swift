//
//  LoginVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/5/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginBtnPressed(btn: UIButton) {
        self.performSegue(withIdentifier: SEGUE_LOGIN, sender: nil)
    }

}
