//
//  ProfileCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/16/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ProfileCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupViews()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate let titleLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.lightGray
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    fileprivate let contentLbl: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    func setupViews() {
        addSubview(titleLbl)
        addSubview(contentLbl)
        addConstraintsWithFormat("H:|-15-[v0]-15-|", views: titleLbl)
        addConstraintsWithFormat("H:|-15-[v0]-15-|", views: contentLbl)
        addConstraintsWithFormat("V:|-8-[v0]-3-[v1]-8-|", views: titleLbl, contentLbl)
    }
    
    func configureCell(title: String, content: String) {
        self.titleLbl.text = title
        self.contentLbl.text = content
    }
}
