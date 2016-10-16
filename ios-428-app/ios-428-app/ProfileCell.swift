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
    
    fileprivate let titleLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.lightGray
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let contentLbl: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }()

    override func setupViews() {
        addSubview(titleLbl)
        addSubview(contentLbl)
        
        addConstraintsWithFormat("H:|-15-[v0]-15-|", views: titleLbl)
        addConstraintsWithFormat("H:|-15-[v0]-15-|", views: contentLbl)
        addConstraintsWithFormat("V:|[v0]-3-[v1]|", views: titleLbl, contentLbl)
    }
    
    func configureCell(title: String, content: String) {
        self.titleLbl.text = title
        self.contentLbl.text = content
    }
}
