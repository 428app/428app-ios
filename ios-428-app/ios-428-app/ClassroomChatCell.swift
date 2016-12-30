//
//  ClassroomChatCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ClassroomChatCell: BaseCollectionCell {
    
    fileprivate var message: ClassroomMessage!
    open var shouldExpand = false
    fileprivate let TEXT_VIEW_FONT = UIFont.systemFont(ofSize: 16.0)
    
    fileprivate let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.black
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let messageTextView: UITextView = {
        var textView = UITextView()
        textView.backgroundColor = UIColor.clear
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.tintColor = RED_UICOLOR
        textView.dataDetectorTypes = .all
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        return textView
    }()
    
    fileprivate let textBubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()
    
    fileprivate lazy var posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.openProfile))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()
    
    func openProfile() {
        NotificationCenter.default.post(name: NOTIF_OPENPROFILE, object: nil, userInfo: ["uid": self.message.posterUid])
    }
    
    fileprivate let BUBBLE_RECIPIENT_IMAGE = UIImage(named: "bubble_recipient")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    fileprivate let BUBBLE_ME_IMAGE = UIImage(named: "bubble_me")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    
    fileprivate let bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    override func setupViews() {
        super.setupViews()
        self.messageTextView.font = TEXT_VIEW_FONT
        addSubview(textBubbleView)
        addSubview(messageTextView)
        addSubview(posterImageView)
        
        addConstraintsWithFormat("H:|-8-[v0(30)]", views: posterImageView)
        addConstraintsWithFormat("V:|-5-[v0(30)]", views: posterImageView)
        
        textBubbleView.addSubview(bubbleImageView)
        textBubbleView.addConstraintsWithFormat("H:|[v0]|", views: bubbleImageView)
        textBubbleView.addConstraintsWithFormat("V:|[v0]|", views: bubbleImageView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(notifyControllerToExpand))
        messageTextView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    fileprivate func loadPosterImage() {
        // Loads image asynchronously and efficiently
        let imageUrlString = self.message.posterImageName
        self.posterImageView.af_cancelImageRequest()
        guard let imageUrl = URL(string: imageUrlString) else {
            self.posterImageView.image = #imageLiteral(resourceName: "placeholder-user")
            return
        }
        
        self.posterImageView.af_setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "placeholder-user"), filter: nil, progress: nil, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false, completion: { imageResponse in
            // Image finished downloading, so cache it - this is mostly for push notifications, as internally af_setImage already has its own cache
            if let imageData = imageResponse.data, let image = UIImage(data: imageData) {
                imageCache.add(image, withIdentifier: imageUrl.absoluteString)
            }
        })
    }
    
    func configureCell(messageObj: ClassroomMessage, viewWidth: CGFloat, isLastInChain: Bool) {
        self.message = messageObj

        // Attributed text is crucial, normal text will screw up if emoji is sent
        let messageText = self.message.text
        self.messageTextView.attributedText = NSAttributedString(string: messageText, attributes: [NSFontAttributeName: TEXT_VIEW_FONT])
        
        self.nameLabel.text = self.message.posterName
        
        // Download poster profile image
        loadPosterImage()
        
        let size = CGSize(width: 250, height: CGFloat.greatestFiniteMagnitude)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: self.message.text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: TEXT_VIEW_FONT], context: nil)
        
        if !self.message.isSentByYou {
            
            // Message on left side 
            
            addSubview(nameLabel)
            self.nameLabel.frame = CGRect(x: 45 + 13, y: 12, width: estimatedFrame.width, height: 18)
            self.messageTextView.frame = CGRect(x: 45 + 8, y: 21, width: estimatedFrame.width + 14, height: estimatedFrame.height + 16)
            self.posterImageView.isHidden = false
            self.messageTextView.textColor = UIColor.black
            // No difference between isLastInChain or not for non sender, just apply tails to all
            self.textBubbleView.frame = CGRect(x: 45 - 8, y: 0, width: estimatedFrame.width + 20 + 8 + 8, height: estimatedFrame.height + 16 + 6 + 19)
            self.bubbleImageView.backgroundColor = UIColor.clear
            self.bubbleImageView.image = BUBBLE_RECIPIENT_IMAGE
            self.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)

        } else {
            
            // Message on right side 
            
            nameLabel.removeFromSuperview()
            self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 2, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
            self.posterImageView.isHidden = true
            self.messageTextView.textColor = UIColor.white
            
            if isLastInChain {
                self.bubbleImageView.backgroundColor = UIColor.clear
                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: 0, width: estimatedFrame.width + 20 + 8 + 8, height: estimatedFrame.height + 16 + 6)
                self.bubbleImageView.image = BUBBLE_ME_IMAGE
                self.bubbleImageView.tintColor = GREEN_UICOLOR
            } else {
                self.bubbleImageView.image = nil
                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: 2, width: estimatedFrame.width + 20 + 8, height: estimatedFrame.height + 16)
                self.bubbleImageView.backgroundColor = GREEN_UICOLOR
            }
        }
    }
    
    func notifyControllerToExpand(tap: UITapGestureRecognizer) {
        self.shouldExpand = true
        NotificationCenter.default.post(name: NOTIF_EXPANDCLASSROOMCHATCELL, object: nil)
    }
    
}
