//
//  ChatVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    private var chatItems = [ChatItem]()
    
    var connection: Connection!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNavController()
        self.stubData()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140
        
    }
    
    // MARK: Table view
    
    private func stubData() {
        let c1 = ChatItem(message: "Hello how are you!", isOther: true, otherPic: "leo-profile")
        let c2 = ChatItem(message: "I'm good how about you? I'm good how about you? I'm good how about you? I'm good how about you? I'm good how about you?", isOther: false, otherPic: nil)

        let c3 = ChatItem(message: "k!", isOther: true, otherPic: "leo-profile")
        chatItems.append(c1)
        chatItems.append(c2)
        chatItems.append(c3)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // TODO: To change into section headers for dates
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chatItem = self.chatItems[indexPath.row]
        if chatItem.isOther {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OtherChatCell", for: indexPath) as! OtherChatCell
            cell.configureCell(chatItemObj: chatItem)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyChatCell", for: indexPath) as! MyChatCell
            cell.configureCell(chatItemObj: chatItem)
            return cell
        }
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
