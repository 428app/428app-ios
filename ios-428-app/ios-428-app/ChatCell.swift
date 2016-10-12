//
//  ChatCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ChatCell: BaseCell {
    
    fileprivate var message: Message!
    
    fileprivate let messageTextView: UITextView = {
        var textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.backgroundColor = UIColor.clear
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isEditable = false
        return textView
    }()
    
    fileprivate let textBubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        return view
    }()
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    fileprivate let BUBBLE_RECIPIENT_IMAGE = UIImage(named: "bubble_recipient")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    fileprivate let BUBBLE_ME_IMAGE = UIImage(named: "bubble_me")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    
    fileprivate let bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    override func setupViews() {
        super.setupViews()
        addSubview(textBubbleView)
        addSubview(messageTextView)
        addSubview(profileImageView)
        
        addConstraintsWithFormat("H:|-8-[v0(30)]", views: profileImageView)
        addConstraintsWithFormat("V:[v0(30)]|", views: profileImageView)
        
        textBubbleView.addSubview(bubbleImageView)
        textBubbleView.addConstraintsWithFormat("H:|[v0]|", views: bubbleImageView)
        textBubbleView.addConstraintsWithFormat("V:|[v0]|", views: bubbleImageView)
    }
    
    func configureCell(messageObj: Message?, viewWidth: CGFloat) {
        if messageObj == nil {
            self.isHidden = true
            return
        }
        self.message = messageObj!
        guard let messageText = self.message.text, let profileImageName = self.message.friend?.profileImageName else {
            self.isHidden = true
            return
        }
        self.messageTextView.isScrollEnabled = true
        self.messageTextView.text = self.message?.text

        self.profileImageView.image = UIImage(named: profileImageName)
        
        let size = CGSize(width: 250, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: FONT_MEDIUM_MID], context: nil)
        if !self.message.isSender {
            self.messageTextView.frame = CGRect(x: 45 + 8, y: -4, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
            self.textBubbleView.frame = CGRect(x: 45 - 8, y: -4, width: estimatedFrame.width + 16 + 8 + 8, height: estimatedFrame.height + 16 + 6)
            self.profileImageView.isHidden = false
            self.bubbleImageView.image = BUBBLE_RECIPIENT_IMAGE
            self.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
            self.messageTextView.textColor = UIColor.black
        } else {
            self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: -4, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
            self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: -4, width: estimatedFrame.width + 16 + 8 + 8, height: estimatedFrame.height + 16 + 6)
            self.profileImageView.isHidden = true
            self.bubbleImageView.image = BUBBLE_ME_IMAGE
            self.bubbleImageView.tintColor = GREEN_UICOLOR
            self.messageTextView.textColor = UIColor.white
        }
        self.messageTextView.sizeToFit()
        self.messageTextView.isScrollEnabled = false
    }
    
}
