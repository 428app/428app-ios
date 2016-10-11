//
//  MyChatCell.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class MyChatCell: UITableViewCell {

//    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageLbl: UILabel!
    
    private var chatItem: ChatItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(chatItemObj: ChatItem) {
        self.chatItem = chatItemObj
        self.messageLbl.text = self.chatItem.message
    }
}
