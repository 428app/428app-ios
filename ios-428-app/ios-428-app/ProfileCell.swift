//
//  ProfileCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/16/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ProfileCell: BaseCell {
    
    let infoLbl: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.black
        return label
    }()

    override func setupViews() {
        infoLbl.text = "Harvard University"
        addSubview(infoLbl)
        addConstraintsWithFormat("H:|[v0]|", views: infoLbl)
        addConstraintsWithFormat("V:|[v0]|", views: infoLbl)
    }
}
