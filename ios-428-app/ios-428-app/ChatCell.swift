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
        log.info("Touches began")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.info("Touches moved")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.info("Touches ended")
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
    
    fileprivate var message: ConnectionMessage!
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
        addConstraintsWithFormat("V:|-3-[v0(30)]", views: profileImageView)
        
        textBubbleView.addSubview(bubbleImageView)
        textBubbleView.addConstraintsWithFormat("H:|[v0]|", views: bubbleImageView)
        textBubbleView.addConstraintsWithFormat("V:|[v0]|", views: bubbleImageView)
        
    }
    
    fileprivate func populateCellWithImage(image: UIImage?) {
        self.profileImageView.image = image
    }
    
    func isAllEmoji(aString: String) -> Bool {
        for scalar in aString.unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F680...0x1F6FF, // Transport and Map
            0x2600...0x26FF,   // Misc symbols
            0x2700...0x27BF,   // Dingbats
            0xFE00...0xFE0F,   // Variation Selectors
            0x0030...0x0039,
            0x00A9...0x00AE,
            0x203C...0x2049,
            0x2122...0x3299,
            0x1F004...0x1F251,
            0x1F910...0x1F990:
                break
            default:
                return false
            }
        }
        return true
    }
    
    

    
    func configureCell(messageObj: ConnectionMessage, viewWidth: CGFloat, isLastInChain: Bool) {
        self.message = messageObj
        let messageText = self.message.text
        self.messageTextView.isScrollEnabled = true
        self.messageTextView.text = self.message?.text

        // Download profile image
        self.request = downloadImage(imageUrlString: self.message.connection.profileImageName, completed: { (image) in
            self.populateCellWithImage(image: image)
        })
        
        let size = CGSize(width: 250.0, height: CGFloat.greatestFiniteMagnitude)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        let sizeFit = messageTextView.sizeThatFits(size)
        
        var estimatedFrame: CGRect!
        
        estimatedFrame = CGRect(x: 0.0, y: 0.0, width: sizeFit.width, height: sizeFit.height)
        
        if isAllEmoji(aString: messageText) {
            // TODO: Fix the emoji
            
            
            estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: TEXT_VIEW_FONT], context: nil)
            log.info("emoji text: \(messageText) and frame: \(estimatedFrame)")
        } else {
            estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: TEXT_VIEW_FONT], context: nil)
            log.info("normal text: \(messageText) and frame: \(estimatedFrame)")
            
        }

        // Bunch of math going here: No need to tune these numbers, they look fine on all screens
        
        if !self.message.isSentByYou {
            
            // Message on right side 
            
            self.profileImageView.isHidden = false
            self.messageTextView.textColor = UIColor.black
            
            if isLastInChain {
                // Apply tail
                self.messageTextView.frame = CGRect(x: 45 + 8, y: 3, width: estimatedFrame.width + 14, height: estimatedFrame.height + 16)
                self.textBubbleView.frame = CGRect(x: 45 - 8, y: 0, width: estimatedFrame.width + 20 + 8 + 8, height: estimatedFrame.height + 16 + 8)
                self.bubbleImageView.backgroundColor = UIColor.clear
                self.bubbleImageView.image = BUBBLE_RECIPIENT_IMAGE
                self.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
            } else {
                self.messageTextView.frame = CGRect(x: 45 + 8, y: 0, width: estimatedFrame.width + 14, height: estimatedFrame.height + 16)
                self.bubbleImageView.image = nil
                self.textBubbleView.frame = CGRect(x: 45, y: 2, width: estimatedFrame.width + 20 + 8, height: estimatedFrame.height + 16)
                self.bubbleImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
            }
        } else {
            
            // Message on left side
            
            self.profileImageView.isHidden = true
            self.messageTextView.textColor = UIColor.white
            
            if isLastInChain {
                // Apply tail
                self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 3, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
                self.bubbleImageView.backgroundColor = UIColor.clear
                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: -1, width: estimatedFrame.width + 20 + 8 + 8, height: estimatedFrame.height + 16 + 8)
                self.bubbleImageView.image = BUBBLE_ME_IMAGE
                self.bubbleImageView.tintColor = GREEN_UICOLOR
            } else {
                self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
                self.bubbleImageView.image = nil
                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: 0, width: estimatedFrame.width + 20 + 8, height: estimatedFrame.height + 16)
                self.bubbleImageView.backgroundColor = GREEN_UICOLOR
            }
        }
        self.messageTextView.isScrollEnabled = false
    }
    
    func notifyControllerToExpand(tap: UITapGestureRecognizer) {
        self.shouldExpand = true
        NotificationCenter.default.post(name: NOTIF_EXPANDCHATCELL, object: nil)
    }
    
}
