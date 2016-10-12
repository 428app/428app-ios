//
//  ConnectionCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ConnectionCell: BaseCell {
    
    fileprivate var message: Message!
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? GREEN_UICOLOR : UIColor.white
            nameLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
            timeLabel.textColor = isHighlighted ? UIColor.white : UIColor.gray
            messageLabel.textColor = isHighlighted ? UIColor.white : UIColor.gray
            disciplineImageView.tintColor = isHighlighted ? UIColor.white : GREEN_UICOLOR
        }
    }
    
    fileprivate func formatDateToText(date: Date) -> String {
        var text = ""
        let dateFormatter = DateFormatter()
        let elapsedTimeInSeconds = Date().timeIntervalSince(date as Date)
        let secondInDays: TimeInterval = 60 * 60 * 24
        if elapsedTimeInSeconds > 7 * secondInDays { // More than 7 days ago
            dateFormatter.dateFormat = "d MMM yyyy"
            text = dateFormatter.string(from: date as Date)
        } else if elapsedTimeInSeconds >= 2 * secondInDays { // 2 - 7 days ago
            dateFormatter.dateFormat = "EEE"
            text = dateFormatter.string(from: date as Date)
        } else if elapsedTimeInSeconds > secondInDays { // 1 - 2 days ago
            text = "Yesterday"
        } else { // Today
            dateFormatter.dateFormat = "h:mm a"
            text = dateFormatter.string(from: date as Date).lowercased()
        }
        return text
    }
    
    fileprivate let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        return label
    }()
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    fileprivate let disciplineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = GREEN_UICOLOR
        return imageView
    }()
    
    fileprivate let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.textColor = UIColor.gray
        return label
    }()
    
    fileprivate let timeLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_LIGHT_SMALL
        label.textColor = UIColor.gray
        label.textAlignment = .right
        return label
    }()
    
    fileprivate let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    override func setupViews() {
        backgroundColor = UIColor.white
        addSubview(profileImageView)
        addSubview(dividerLineView)
        
        setupContainerView()
        
        addConstraintsWithFormat("H:|-12-[v0(68)]", views: profileImageView)
        addConstraintsWithFormat("V:[v0(68)]", views: profileImageView)
        
        addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraintsWithFormat("H:|-82-[v0]|", views: dividerLineView)
        addConstraintsWithFormat("V:[v0(1)]|", views: dividerLineView)
    }
    
    fileprivate func setupContainerView() {
        let containerView = UIView()
        addSubview(containerView)
        addConstraintsWithFormat("H:|-90-[v0]|", views: containerView)
        addConstraintsWithFormat("V:[v0(60)]", views: containerView)
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(disciplineImageView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addConstraintsWithFormat("H:|[v0(16)]-5-[v1][v2(80)]-12-|", views: disciplineImageView, nameLabel, timeLabel)
        containerView.addConstraintsWithFormat("H:|[v0]-12-|", views: messageLabel)
        containerView.addConstraintsWithFormat("V:|[v0][v1(24)]|", views: nameLabel, messageLabel)
        containerView.addConstraintsWithFormat("V:|-7-[v0(24)]", views: timeLabel)
        containerView.addConstraintsWithFormat("V:|-8-[v0(16)]", views: disciplineImageView)
    }
    
    func configureCell(messageObj: Message?) {
        if messageObj == nil {
            self.isHidden = true
            return
        }
        self.message = messageObj!
        self.nameLabel.text = self.message.friend?.name
        if let profileImageName = self.message.friend?.profileImageName {
            self.profileImageView.image = UIImage(named: profileImageName)
        }
        if let disciplineImageName = self.message.friend?.disciplineImageName {
            self.disciplineImageView.image = UIImage(named: disciplineImageName)
        }
        self.messageLabel.text = self.message.text
        if let date = self.message.date {
            self.timeLabel.text = formatDateToText(date: date)
        }
    }
}
