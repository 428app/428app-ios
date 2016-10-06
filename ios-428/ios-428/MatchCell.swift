//
//  MatchCell.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class MatchCell: UITableViewCell {
    
    private var match: Match!

    @IBOutlet weak var userImgView: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var msgLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(matchObj: Match) {
        self.match = matchObj
        self.userImgView.image = UIImage(named: self.match.userPicUrl)
        self.userNameLbl.text = self.match.username
        self.msgLbl.text = self.match.recentMsg
        self.timeLbl.text = self.match.lastSentTimeString
    }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
//    }

}
