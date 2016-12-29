////
////  ClassroomChatCell.swift
////  ios-428-app
////
////  Created by Leonard Loo on 10/19/16.
////  Copyright © 2016 428. All rights reserved.
////
//
//import Foundation
//import UIKit
//
//class ClassroomChatCell: BaseCollectionCell {
//    
//    fileprivate var message: ClassroomMessage!
//    open var shouldExpand = false
//    fileprivate let TEXT_VIEW_FONT = UIFont.systemFont(ofSize: 16.0)
//    
//    fileprivate let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = FONT_HEAVY_MID
//        label.textColor = UIColor.black
//        label.textAlignment = .left
//        return label
//    }()
//    
//    fileprivate let messageTextView: UITextView = {
//        var textView = UITextView()
//        textView.backgroundColor = UIColor.clear
//        textView.showsHorizontalScrollIndicator = false
//        textView.showsVerticalScrollIndicator = false
//        textView.isEditable = false
//        textView.isSelectable = true
//        textView.tintColor = RED_UICOLOR
//        textView.dataDetectorTypes = .all
//        textView.isUserInteractionEnabled = true
//        return textView
//    }()
//    
//    fileprivate let textBubbleView: UIView = {
//        let view = UIView()
//        view.layer.cornerRadius = 15
//        view.layer.masksToBounds = true
//        view.isUserInteractionEnabled = true
//        return view
//    }()
//    
//    fileprivate lazy var disciplineImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = GREEN_UICOLOR
//        imageView.layer.cornerRadius = 15
//        imageView.layer.masksToBounds = true
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openProfile))
//        imageView.isUserInteractionEnabled = true
//        imageView.addGestureRecognizer(tapGestureRecognizer)
//        return imageView
//    }()
//    
//    func openProfile() {
//        NotificationCenter.default.post(name: NOTIF_OPENPROFILE, object: nil, userInfo: ["uid": self.message.posterUid])
//    }
//    
//    fileprivate let BUBBLE_RECIPIENT_IMAGE = UIImage(named: "bubble_recipient")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
//    fileprivate let BUBBLE_ME_IMAGE = UIImage(named: "bubble_me")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
//    
//    fileprivate let bubbleImageView: UIImageView = {
//        let imageView = UIImageView()
//        return imageView
//    }()
//    
//    override func setupViews() {
//        super.setupViews()
//        self.messageTextView.font = TEXT_VIEW_FONT
//        addSubview(textBubbleView)
//        addSubview(messageTextView)
//        addSubview(disciplineImageView)
//        
//        addConstraintsWithFormat("H:|-9-[v0(30)]", views: disciplineImageView)
//        addConstraintsWithFormat("V:[v0(30)]|", views: disciplineImageView)
//        
//        textBubbleView.addSubview(bubbleImageView)
//        textBubbleView.addConstraintsWithFormat("H:|[v0]|", views: bubbleImageView)
//        textBubbleView.addConstraintsWithFormat("V:|[v0]|", views: bubbleImageView)
//        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(notifyControllerToExpand))
//        messageTextView.addGestureRecognizer(tapGestureRecognizer)
//        
//    }
//    
//    func configureCell(messageObj: ClassroomMessage, viewWidth: CGFloat, isLastInChain: Bool) {
//        self.message = messageObj
//        self.messageTextView.isScrollEnabled = true
//        self.messageTextView.text = self.message.text
//        self.nameLabel.text = self.message.posterName
//        
//        self.disciplineImageView.image = UIImage(named: self.message.posterDiscipline)
//        
//        let size = CGSize(width: 250, height: 1000)
//        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
//        let estimatedFrame = NSString(string: self.message.text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: TEXT_VIEW_FONT], context: nil)
//        if !self.message.isSentByYou {
//            addSubview(nameLabel)
//            self.nameLabel.frame = CGRect(x: 45 + 13, y: 12, width: estimatedFrame.width, height: 18)
//            self.messageTextView.frame = CGRect(x: 45 + 8, y: 21, width: estimatedFrame.width + 14, height: estimatedFrame.height + 16)
//            self.disciplineImageView.isHidden = false
//            self.messageTextView.textColor = UIColor.black
//            // No difference between isLastInChain or not for non sender, just apply tails to all
//            self.textBubbleView.frame = CGRect(x: 45 - 8, y: 0, width: estimatedFrame.width + 20 + 8 + 8, height: estimatedFrame.height + 16 + 6 + 19)
//            self.bubbleImageView.backgroundColor = UIColor.clear
//            self.bubbleImageView.image = BUBBLE_RECIPIENT_IMAGE
//            self.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
//
//        } else {
//            nameLabel.removeFromSuperview()
//            self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 2, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
//            self.disciplineImageView.isHidden = true
//            self.messageTextView.textColor = UIColor.white
//            
//            if isLastInChain {
//                self.bubbleImageView.backgroundColor = UIColor.clear
//                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: 0, width: estimatedFrame.width + 20 + 8 + 8, height: estimatedFrame.height + 16 + 6)
//                self.bubbleImageView.image = BUBBLE_ME_IMAGE
//                self.bubbleImageView.tintColor = GREEN_UICOLOR
//            } else {
//                self.bubbleImageView.image = nil
//                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: 2, width: estimatedFrame.width + 20 + 8, height: estimatedFrame.height + 16)
//                self.bubbleImageView.backgroundColor = GREEN_UICOLOR
//            }
//        }
//        self.messageTextView.isScrollEnabled = false
//    }
//    
//    func notifyControllerToExpand(tap: UITapGestureRecognizer) {
//        self.shouldExpand = true
//        NotificationCenter.default.post(name: NOTIF_EXPANDTOPICCELL, object: nil)
//    }
//    
//}
