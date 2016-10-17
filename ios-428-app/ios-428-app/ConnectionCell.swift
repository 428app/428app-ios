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
            timeLabel.textColor = isHighlighted ? UIColor.white : UIColor.lightGray
            messageLabel.textColor = isHighlighted ? UIColor.white : UIColor.gray
            disciplineImageView.tintColor = isHighlighted ? UIColor.white : GREEN_UICOLOR
            repliedImageView.tintColor = isHighlighted ? UIColor.white : UIColor.lightGray
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
    
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    // Container views
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        return label
    }()
    
    fileprivate let disciplineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = GREEN_UICOLOR
        return imageView
    }()
    
    fileprivate let messageLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_SMALLMID
        label.textColor = UIColor.lightGray
        return label
    }()
    
    fileprivate let repliedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "replied")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.lightGray
        return imageView
    }()
    
    fileprivate let timeLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_SMALLMID
        label.textColor = UIColor.lightGray
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
        addSubview(containerView)
        
        addConstraintsWithFormat("H:|-90-[v0]|", views: containerView)
        addConstraintsWithFormat("V:[v0(60)]", views: containerView)
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraintsWithFormat("H:|-12-[v0(68)]", views: profileImageView)
        addConstraintsWithFormat("V:[v0(68)]", views: profileImageView)
        addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraintsWithFormat("H:|-90-[v0]|", views: dividerLineView)
        addConstraintsWithFormat("V:[v0(1)]|", views: dividerLineView)
        
        setupContainerView()
    }
    
    fileprivate func setupContainerView() {
        // Container is the message container
        containerView.addSubview(nameLabel)
        containerView.addSubview(disciplineImageView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addConstraintsWithFormat("H:|[v0(16)]-5-[v1][v2(80)]-12-|", views: disciplineImageView, nameLabel, timeLabel)
        containerView.addConstraintsWithFormat("V:|[v0][v1(24)]|", views: nameLabel, messageLabel)
        containerView.addConstraintsWithFormat("V:|-7-[v0(24)]", views: timeLabel)
        containerView.addConstraintsWithFormat("V:|-8-[v0(16)]", views: disciplineImageView)
    }
    
    fileprivate var constraintsToDelete = [NSLayoutConstraint]()
    
    func configureCell(messageObj: Message) {
        self.message = messageObj
        self.nameLabel.text = self.message.friend.name
        self.profileImageView.image = UIImage(named: self.message.friend.profileImageName)
        self.disciplineImageView.image = UIImage(named: self.message.friend.disciplineImageName)
        self.messageLabel.text = self.message.text
        self.timeLabel.text = formatDateToText(date: self.message.date)
        
        containerView.removeConstraints(constraintsToDelete)
        repliedImageView.removeFromSuperview()
        constraintsToDelete = [NSLayoutConstraint]()
        
        if message.isSender {
            containerView.addSubview(repliedImageView)
            constraintsToDelete.append(contentsOf: containerView.addAndGetConstraintsWithFormat("H:|[v0(16)]-3-[v1]-12-|", views: repliedImageView, messageLabel))
            let topOfRepliedConstraint = NSLayoutConstraint(item: repliedImageView, attribute: .top, relatedBy: .equal, toItem: disciplineImageView, attribute: .bottom, multiplier: 1.0, constant: 15.0)
            containerView.addConstraint(topOfRepliedConstraint)
            constraintsToDelete.append(topOfRepliedConstraint)
            constraintsToDelete.append(contentsOf: containerView.addAndGetConstraintsWithFormat("V:[v0(16)]", views: repliedImageView))
        } else {
            constraintsToDelete.append(contentsOf: containerView.addAndGetConstraintsWithFormat("H:|[v0]-12-|", views: messageLabel))
        }
        
        if message.isSeen {
            timeLabel.textColor = UIColor.lightGray
            messageLabel.textColor = UIColor.lightGray
        } else {
            timeLabel.textColor = UIColor.black
            messageLabel.textColor = UIColor.black
        }
    }
}
