//
//  ConnectionCell.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class ConnectionCell: UITableViewCell {
    
    private var connection: Connection!

    @IBOutlet weak var userImgView: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var msgLbl: UILabel!
    @IBOutlet weak var disciplineImgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(connectionObj: Connection) {
        self.connection = connectionObj
        self.userImgView.image = UIImage(named: self.connection.userPicUrl)
        self.userNameLbl.text = self.connection.username
        self.msgLbl.text = self.connection.recentMsg
        self.disciplineImgView.image = UIImage(named: self.connection.discipline)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
