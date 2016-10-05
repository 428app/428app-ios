//
//  MatchesVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/5/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class MatchesVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNavController()
    }

    private func initNavController() {
        self.navigationItem.title = "Matches"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings-U"), style: .plain, target: self, action: #selector(MatchesVC.goToSettings))
    }
    
    func goToSettings() {
        self.performSegue(withIdentifier: SEGUE_SETTINGS, sender: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
