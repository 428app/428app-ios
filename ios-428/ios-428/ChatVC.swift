//
//  ChatVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class ChatVC: UIViewController {
    
    var connection: Connection!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNavController()
    }

    private func initNavController() {
        self.navigationItem.title = self.connection.username
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "More"), style: .plain, target: self, action: #selector(ChatVC.morePressed))
    }
    
    func morePressed() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tintColor = GREEN_UICOLOR
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let muteAction = UIAlertAction(title: "Mute Notifications", style: .default) { (action) in
            // TODO: Fill in Mute action
        }
        alertController.addAction(muteAction)
        
        let reportAction = UIAlertAction(title: "Report \(self.connection.username)", style: .default) { (action) in
            // TODO: Fill in report action
        }
        alertController.addAction(reportAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}
