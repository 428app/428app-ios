//
//  TopicCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class TopicCell: BaseTableViewCell {
    
    // MARK: Set up views
    fileprivate var topic: Topic!
    
    fileprivate let dateLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let iconImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "topic"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = GREEN_UICOLOR
        return imageView
    }()
    
    fileprivate let messageCountLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .right
        return label
    }()
    
    fileprivate let topicImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizesSubviews = true
        return imageView
    }()
    
    fileprivate let promptLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.numberOfLines = 99
        return label
    }()
    
    override func setupViews() {
        
        let containerView = UIView()
        containerView.layer.cornerRadius = 4.0
        let SHADOW_COLOR: CGFloat =  157.0 / 255.0
        containerView.layer.shadowColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).cgColor
        containerView.layer.shadowOpacity = 0.6
        containerView.layer.shadowRadius = 2.0
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        self.selectionStyle = .none

        self.backgroundColor = GRAY_UICOLOR
        contentView.backgroundColor = GRAY_UICOLOR
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        contentView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: containerView)
        contentView.addConstraintsWithFormat("V:|-8-[v0]-8-|", views: containerView)
        
        containerView.addSubview(dateLabel)
        containerView.addSubview(iconImageView)
        containerView.addSubview(messageCountLabel)
        containerView.addSubview(topicImageView)
        containerView.addSubview(promptLabel)
        
        containerView.addConstraintsWithFormat("V:|-8-[v0(25)]-8-[v1(175)]-12-[v2]-12-|", views: dateLabel, topicImageView, promptLabel)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-[v1(60)]-3-[v2(16)]-8-|", views: dateLabel, messageCountLabel, iconImageView)
        containerView.addConstraintsWithFormat("V:[v0(16)]", views: iconImageView)
        containerView.addConstraintsWithFormat("V:[v0(20)]", views: messageCountLabel)
        containerView.addConstraint(NSLayoutConstraint(item: iconImageView, attribute: .centerY, relatedBy: .equal, toItem: dateLabel, attribute: .centerY, multiplier: 1.0, constant: -2.0))
        containerView.addConstraint(NSLayoutConstraint(item: messageCountLabel, attribute: .centerY, relatedBy: .equal, toItem: dateLabel, attribute: .centerY, multiplier: 1.0, constant: 0))
        containerView.addConstraintsWithFormat("H:|[v0]|", views: topicImageView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: promptLabel)
    }
    
    func configureCell(topic: Topic) {
        self.topic = topic
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"
        dateLabel.text = ""
        if let dateString = topic.dateString {
            dateLabel.text = dateString
        }
        messageCountLabel.text = "\(topic.topicMessages.count)"
        topicImageView.image = UIImage(named: topic.imageName)
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let formatedPrompt = NSMutableAttributedString(string: topic.prompt, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        promptLabel.attributedText = formatedPrompt
        
        if topic.isSeen {
            self.messageCountLabel.textColor = GREEN_UICOLOR
            self.iconImageView.tintColor = GREEN_UICOLOR
        } else {
            self.messageCountLabel.textColor = RED_UICOLOR
            self.iconImageView.tintColor = RED_UICOLOR
        }
    }
    
}
