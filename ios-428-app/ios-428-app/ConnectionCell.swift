//
//  ConnectionCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireImage

class ConnectionCell: BaseCollectionCell {
    
    // NOTE: If message has an empty text, it means this is a new connection because we disallow empty 
    // messages from being sent to the server
    
    fileprivate var message: Message! {
        didSet {
            self.isNewConnection = self.message.text.isEmpty
        }
    }
    fileprivate var isNewConnection: Bool = false
    
    override var isHighlighted: Bool {
        didSet {

            nameLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
            timeLabel.textColor = isHighlighted ? UIColor.white : UIColor.lightGray
            messageLabel.textColor = isHighlighted ? UIColor.white : UIColor.lightGray
            
            if isNewConnection {
                backgroundColor = isHighlighted ? RED_UICOLOR : UIColor.white
                disciplineImageView.tintColor = isHighlighted ? UIColor.white : RED_UICOLOR
            } else {
                backgroundColor = isHighlighted ? GREEN_UICOLOR : UIColor.white
                disciplineImageView.tintColor = isHighlighted ? UIColor.white : GREEN_UICOLOR
            }
            
            repliedImageView.tintColor = isHighlighted ? UIColor.white : UIColor.lightGray
        }
    }
    
    fileprivate func formatDateToText(date: Date) -> String {
        var text = ""
        let dateFormatter = DateFormatter()
        let elapsedTimeInSeconds = Date().timeIntervalSince(date as Date)
        let secondInDays: TimeInterval = 60 * 60 * 24
        if elapsedTimeInSeconds > 365 * secondInDays { // More than 1 year
            dateFormatter.dateFormat = "d MMM yy"
            text = dateFormatter.string(from: date as Date)
        } else if elapsedTimeInSeconds > 7 * secondInDays { // More than 7 days ago
            dateFormatter.dateFormat = "d MMM"
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
        imageView.frame = CGRect(x: 0.0, y: 0.0, width: 68.0, height: 68.0)
        return imageView
    }()
    
    // Container views
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_XLARGE
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
        label.font = FONT_MEDIUM_MID
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
        label.font = FONT_MEDIUM_MID
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
        addConstraintsWithFormat("V:[v0(0.5)]|", views: dividerLineView)
        
        setupContainerView()
    }
    
    fileprivate func setupContainerView() {
        // Container is the message container
        containerView.addSubview(nameLabel)
        containerView.addSubview(disciplineImageView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addConstraintsWithFormat("H:|[v0(16)]-5-[v1][v2(100)]-12-|", views: disciplineImageView, nameLabel, timeLabel)
        containerView.addConstraintsWithFormat("V:|[v0]-(-14)-[v1(24)]-3-|", views: nameLabel, messageLabel)
        containerView.addConstraintsWithFormat("V:|-13-[v0(24)]", views: timeLabel)
        containerView.addConstraintsWithFormat("V:|-14-[v0(16)]", views: disciplineImageView)
    }
    
    fileprivate var constraintsToDelete = [NSLayoutConstraint]()
    fileprivate var imageActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.isHidden = false
        indicator.alpha = 1.0
        indicator.center = CGPoint(x: 34.0, y: 34.0)
        return indicator
    }()

    fileprivate func loadImage() {
//        self.profileImageView.image = nil
        let imageUrlString = self.message.connection.profileImageName
        self.profileImageView.af_cancelImageRequest()
        guard let imageUrl = URL(string: imageUrlString) else {
            self.profileImageView.image = #imageLiteral(resourceName: "placeholder-user")
            return
        }
        self.profileImageView.af_setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "placeholder-user"), filter: nil, progress: nil, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false, completion: { image in
            // Image finished downloading
        })
    }
    
    func configureCell(messageObj: Message) {
        self.message = messageObj
        self.loadImage()
        
        self.nameLabel.text = self.message.connection.name
        self.disciplineImageView.image = UIImage(named: self.message.connection.disciplineImageName)
        
        if isNewConnection {
            // New connection
            self.messageLabel.text = "New connection!"
            self.disciplineImageView.tintColor = RED_UICOLOR
        } else {
            self.messageLabel.text = self.message.text
            self.disciplineImageView.tintColor = GREEN_UICOLOR
        }
        
        self.timeLabel.text = formatDateToText(date: self.message.date)
        
        containerView.removeConstraints(constraintsToDelete)
        repliedImageView.removeFromSuperview()
        constraintsToDelete = [NSLayoutConstraint]()
        
        if message.isSentByYou {
            containerView.addSubview(repliedImageView)
            constraintsToDelete.append(contentsOf: containerView.addAndGetConstraintsWithFormat("H:|[v0(16)]-3-[v1]-12-|", views: repliedImageView, messageLabel))
            let topOfRepliedConstraint = NSLayoutConstraint(item: repliedImageView, attribute: .top, relatedBy: .equal, toItem: disciplineImageView, attribute: .bottom, multiplier: 1.0, constant: 5.0)
            containerView.addConstraint(topOfRepliedConstraint)
            constraintsToDelete.append(topOfRepliedConstraint)
            constraintsToDelete.append(contentsOf: containerView.addAndGetConstraintsWithFormat("V:[v0(16)]", views: repliedImageView))
        } else {
            constraintsToDelete.append(contentsOf: containerView.addAndGetConstraintsWithFormat("H:|[v0]-12-|", views: messageLabel))
        }
        
        if message.connection.hasNewMessages {
            timeLabel.textColor = UIColor.black
            messageLabel.textColor = UIColor.black
        } else {
            timeLabel.textColor = UIColor.lightGray
            messageLabel.textColor = UIColor.lightGray
        }
    }
}
