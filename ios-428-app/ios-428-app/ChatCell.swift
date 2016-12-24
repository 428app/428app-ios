//
//  ChatCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class CustomTextView: UITextView {
    
    // Override the touches because I don't want any funky behavior from them
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        log.info("Touches began")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        log.info("Touches moved")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        log.info("Touches ended")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copyAll(_:)) {
            return true
        }
        return false
    }
    
    // Function called by selector in the superclass
    func showMenu(location: CGPoint) {
        self.becomeFirstResponder()
        let menuController = UIMenuController.shared
        let copyItem = UIMenuItem(title: "Copy", action: #selector(CustomTextView.copyAll(_:)))
        menuController.menuItems = [copyItem]
        let rect = CGRect(x: location.x - 35, y: self.frame.origin.y, width: 50, height: self.frame.height)
        menuController.setTargetRect(rect, in: self)
        menuController.setMenuVisible(true, animated: true)
    }
    
    func copyAll(_ sender: Any?) {
        UIPasteboard.general.string = self.text
    }
}

class ChatCell: BaseCollectionCell, UITextViewDelegate {
    
    fileprivate var message: PrivateMessage!
    open var shouldExpand = false
    fileprivate let TEXT_VIEW_FONT = UIFont.systemFont(ofSize: 16.0)
    open var request: Request?
    
    fileprivate lazy var messageTextView: CustomTextView = {
        var textView = CustomTextView()
        textView.backgroundColor = UIColor.clear
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.tintColor = RED_UICOLOR
        textView.dataDetectorTypes = .all
        textView.isUserInteractionEnabled = true
        textView.delegate = self
        textView.isScrollEnabled = false
        
        textView.font = self.TEXT_VIEW_FONT
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(selectAllOfTextView))
        textView.addGestureRecognizer(longPress)
        let tap = UITapGestureRecognizer(target: self, action: #selector(notifyControllerToExpand))
        textView.addGestureRecognizer(tap)
        return textView
    }()
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        // TODO: How to disable magnifying glass?
        if !NSEqualRanges(textView.selectedRange, NSMakeRange(0, 0)) {
            textView.selectedRange = NSMakeRange(0, 0);
        }
    }
    
    func selectAllOfTextView(recognizer: UIGestureRecognizer) {
        let loc = recognizer.location(in: self.messageTextView)
        self.messageTextView.showMenu(location: loc)
    }

    fileprivate let textBubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    fileprivate let BUBBLE_RECIPIENT_IMAGE = UIImage(named: "bubble_recipient")?.resizableImage(withCapInsets: UIEdgeInsets(top: 23, left: 26, bottom: 23, right: 26))
    fileprivate let BUBBLE_ME_IMAGE = UIImage(named: "bubble_me")?.resizableImage(withCapInsets: UIEdgeInsets(top: 23, left: 26, bottom: 23, right: 26))
    
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
        addConstraintsWithFormat("V:|-3-[v0(30)]", views: profileImageView)
        
        textBubbleView.addSubview(bubbleImageView)
        textBubbleView.addConstraintsWithFormat("H:|[v0]|", views: bubbleImageView)
        textBubbleView.addConstraintsWithFormat("V:|[v0]|", views: bubbleImageView)
    }
    
    fileprivate func populateCellWithImage(image: UIImage?) {
        self.profileImageView.image = image
    }
    
    func configureCell(messageObj: PrivateMessage, viewWidth: CGFloat, isLastInChain: Bool) {
        self.message = messageObj
        let messageText = self.message.text

        // Attributed text is crucial, normal text will screw up if emoji is sent
        self.messageTextView.attributedText = NSAttributedString(string: self.message!.text, attributes: [NSFontAttributeName: TEXT_VIEW_FONT])
        
        // Download profile image
        self.request = downloadImage(imageUrlString: self.message.privateChat.profileImageName, completed: { (image) in
            self.populateCellWithImage(image: image)
        })
        
        let size = CGSize(width: 250.0, height: CGFloat.greatestFiniteMagnitude)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame: CGRect = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: TEXT_VIEW_FONT], context: nil)
        
        // Bunch of math going here: No need to tune these numbers, they look fine on all screens
        let textBubbleWidth: CGFloat = estimatedFrame.width + 20 + 8
        let textBubbleHeight: CGFloat = estimatedFrame.height + 20
        let messageTextWidth: CGFloat = estimatedFrame.width + 16
        let messageTextHeight: CGFloat = estimatedFrame.height + 20
        
        if self.message.isSentByYou {
            
            // Message on right side
            
            self.profileImageView.isHidden = true
            self.messageTextView.textColor = UIColor.white

            if isLastInChain {
                // Apply tail
                self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 0, width: messageTextWidth, height: messageTextHeight - 2)
                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 12, y: -2, width: textBubbleWidth + 16, height: textBubbleHeight + 2)
                self.bubbleImageView.backgroundColor = UIColor.clear
                self.bubbleImageView.image = BUBBLE_ME_IMAGE
                self.bubbleImageView.tintColor = GREEN_UICOLOR
            } else {
                self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 0, width: messageTextWidth, height: messageTextHeight)
                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: 0, width: textBubbleWidth, height: textBubbleHeight)
                self.bubbleImageView.image = nil
                self.bubbleImageView.backgroundColor = GREEN_UICOLOR
            }

        } else {
    
            // Message on left side
    
            self.profileImageView.isHidden = false
            self.messageTextView.textColor = UIColor.black
            
            if isLastInChain {
                // Apply tail
                self.messageTextView.frame = CGRect(x: 45 + 8, y: 0, width: messageTextWidth, height: messageTextHeight - 2)
                self.textBubbleView.frame = CGRect(x: 45 - 8, y: -2, width: textBubbleWidth + 8, height: textBubbleHeight + 2)
                self.bubbleImageView.backgroundColor = UIColor.clear
                self.bubbleImageView.image = BUBBLE_RECIPIENT_IMAGE
                self.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
            } else {
                self.messageTextView.frame = CGRect(x: 45 + 8, y: 0, width: messageTextWidth, height: messageTextHeight)
                self.textBubbleView.frame = CGRect(x: 45, y: 0, width: textBubbleWidth, height: textBubbleHeight)
                self.bubbleImageView.image = nil
                self.bubbleImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
            }
        }
    }
    
    func notifyControllerToExpand(tap: UITapGestureRecognizer) {
        self.shouldExpand = true
        NotificationCenter.default.post(name: NOTIF_EXPANDCHATCELL, object: nil)
    }
    
}
