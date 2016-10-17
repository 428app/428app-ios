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
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    fileprivate let contentLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    func setupViews() {
        addSubview(titleLabel)
        addSubview(contentLabel)
        addConstraintsWithFormat("H:|-15-[v0]-15-|", views: titleLabel)
        addConstraintsWithFormat("H:|-15-[v0]-15-|", views: contentLabel)
        addConstraintsWithFormat("V:|-8-[v0]-3-[v1]-8-|", views: titleLabel, contentLabel)
    }
    
    func configureCell(title: String, content: String) {
        self.titleLabel.text = title
        self.contentLabel.text = content
    }
}
