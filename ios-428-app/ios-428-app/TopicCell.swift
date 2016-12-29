//
//  ClassroomCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ClassroomCell: BaseTableViewCell {
    
    // MARK: Set up views
    fileprivate var classroom: Classroom!
    
    fileprivate let dateLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let iconImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "classroom"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = GREEN_UICOLOR
        return imageView
    }()
    
    fileprivate let messageCountLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .right
        return label
    }()
    
    fileprivate let classroomImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizesSubviews = true
        return imageView
    }()
    
    fileprivate let promptLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.white
//        label.textAlignment = .left
        label.textAlignment = .center
        label.numberOfLines = 2
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
        
//        containerView.addSubview(dateLabel)
//        containerView.addSubview(iconImageView)
//        containerView.addSubview(messageCountLabel)
        containerView.addSubview(classroomImageView)
        containerView.addSubview(promptLabel)
        
        containerView.addConstraintsWithFormat("V:|[v0(175)]-12-[v1]-12-|", views: classroomImageView, promptLabel)
//        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-[v1(60)]-3-[v2(16)]-8-|", views: dateLabel, messageCountLabel, iconImageView)
//        containerView.addConstraintsWithFormat("V:[v0(16)]", views: iconImageView)
//        containerView.addConstraintsWithFormat("V:[v0(20)]", views: messageCountLabel)
//        containerView.addConstraint(NSLayoutConstraint(item: iconImageView, attribute: .centerY, relatedBy: .equal, toItem: dateLabel, attribute: .centerY, multiplier: 1.0, constant: -2.0))
//        containerView.addConstraint(NSLayoutConstraint(item: messageCountLabel, attribute: .centerY, relatedBy: .equal, toItem: dateLabel, attribute: .centerY, multiplier: 1.0, constant: 0))
        containerView.addConstraintsWithFormat("H:|[v0]|", views: classroomImageView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: promptLabel)
    }
    
    func configureCell(classroom: Classroom) {
        self.classroom = classroom
        dateLabel.text = "Question 1"
        messageCountLabel.text = "4"
        promptLabel.text = "Physics I ClassroomPhysics I ClassroomPhysics I ClassroomPhysics I ClassroomPhysics I "
        let components = classroom.prompt.components(separatedBy: ",")
//        if components.count == 3 {
//            promptLabel.text = components[0]
//            dateLabel.text = components[1]
//            messageCountLabel.text = components[2]
//        }
        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "d MMM yyyy"
//        dateLabel.text = ""
//        if let dateString = classroom.dateString {
//            dateLabel.text = dateString
//        }
        
        classroomImageView.image = UIImage(named: classroom.imageName)
        
        
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineSpacing = 6
//        let formatedPrompt = NSMutableAttributedString(string: classroom.prompt, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
//        promptLabel.attributedText = formatedPrompt
        
        if classroom.hasSeen {
            self.messageCountLabel.textColor = UIColor.darkGray
            self.iconImageView.tintColor = UIColor.darkGray
        } else {
            self.messageCountLabel.textColor = GREEN_UICOLOR
            self.iconImageView.tintColor = GREEN_UICOLOR
        }
    }
    
}
