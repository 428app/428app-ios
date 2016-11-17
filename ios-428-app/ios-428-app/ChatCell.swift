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
        
        textView.translatesAutoresizingMaskIntoConstraints = false
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
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 15
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?

    
    fileprivate let BUBBLE_RECIPIENT_IMAGE = UIImage(named: "bubble_recipient")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    fileprivate let BUBBLE_ME_IMAGE = UIImage(named: "bubble_me")?.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    
    fileprivate let bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func setupViews() {
        super.setupViews()
        addSubview(textBubbleView)
        addSubview(bubbleImageView)
        addSubview(messageTextView)
        addSubview(profileImageView)
        
//        addConstraintsWithFormat("H:|-8-[v0(30)]", views: profileImageView)
//        addConstraintsWithFormat("V:|-3-[v0(30)]", views: profileImageView)
        
        //x,y,w,h
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        //x,y,w,h
        
        bubbleViewRightAnchor = textBubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        
        bubbleViewRightAnchor?.isActive = true
        
        bubbleViewLeftAnchor = textBubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        //        textBubbleViewLeftAnchor?.active = false
        
        
        textBubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        bubbleWidthAnchor = textBubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        
        textBubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        //ios 9 constraints
        //x,y,w,h
        //        messageTextView.rightAnchor.constraintEqualToAnchor(self.rightAnchor).active = true
        messageTextView.leftAnchor.constraint(equalTo: textBubbleView.leftAnchor, constant: 8).isActive = true
        messageTextView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        messageTextView.rightAnchor.constraint(equalTo: textBubbleView.rightAnchor).isActive = true
        //        messageTextView.widthAnchor.constraintEqualToConstant(200).active = true
        
        
        messageTextView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        
        
//        textBubbleView.addSubview(bubbleImageView)
        
        bubbleImageView.centerXAnchor.constraint(equalTo: textBubbleView.centerXAnchor).isActive = true
        bubbleImageView.centerYAnchor.constraint(equalTo: textBubbleView.centerYAnchor).isActive = true
        bubbleImageView.heightAnchor.constraint(equalTo: textBubbleView.heightAnchor).isActive = true
        bubbleImageView.widthAnchor.constraint(equalTo: textBubbleView.widthAnchor).isActive = true
        
//        bubbleImageView.leftAnchor.constraint(equalTo: textBubbleView.leftAnchor, constant: -8.0).isActive = true
//        bubbleImageView.rightAnchor.constraint(equalTo: textBubbleView.rightAnchor).isActive = true
//        bubbleImageView.topAnchor.constraint(equalTo: textBubbleView.topAnchor).isActive = true
//        bubbleImageView.bottomAnchor.constraint(equalTo: textBubbleView.bottomAnchor).isActive = true
        
//        textBubbleView.addConstraintsWithFormat("H:|[v0]|", views: bubbleImageView)
//        textBubbleView.addConstraintsWithFormat("V:|[v0]|", views: bubbleImageView)
        
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
    
    
    fileprivate func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func configureCell(messageObj: ConnectionMessage, viewWidth: CGFloat, isLastInChain: Bool) {
        self.message = messageObj
        let messageText = self.message.text
        self.messageTextView.isScrollEnabled = true
//        self.messageTextView.text = self.message?.text
        
        self.messageTextView.attributedText = NSAttributedString(string: self.message!.text, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)])

        // Download profile image
        self.request = downloadImage(imageUrlString: self.message.connection.profileImageName, completed: { (image) in
            self.populateCellWithImage(image: image)
        })
        
        bubbleWidthAnchor?.constant = estimateFrameForText(text: messageText).width + 32
        
        if self.message.isSentByYou {
            //outgoing blue
            textBubbleView.backgroundColor = GREEN_UICOLOR
            messageTextView.textColor = UIColor.white
            profileImageView.isHidden = true
            
            bubbleViewRightAnchor?.isActive = true
            bubbleViewLeftAnchor?.isActive = false
            
            if isLastInChain {
                log.info("Last")
                
                self.textBubbleView.backgroundColor = UIColor.clear
                self.bubbleImageView.image = #imageLiteral(resourceName: "bubble_me")
                self.bubbleImageView.tintColor = GREEN_UICOLOR
            } else {
                self.bubbleImageView.image = nil
            }
            
        } else {
            //incoming gray
            textBubbleView.backgroundColor = GRAY_UICOLOR
            messageTextView.textColor = UIColor.black
            profileImageView.isHidden = false
            
            bubbleViewRightAnchor?.isActive = false
            bubbleViewLeftAnchor?.isActive = true
            
            if isLastInChain {
                self.textBubbleView.backgroundColor = UIColor.clear
                self.bubbleImageView.image = #imageLiteral(resourceName: "bubble_recipient")
                self.bubbleImageView.tintColor = GRAY_UICOLOR
            } else {
                
                self.bubbleImageView.image = nil
            }
        }
        
        self.messageTextView.isScrollEnabled = false
        
//        let size = CGSize(width: 250.0, height: CGFloat.greatestFiniteMagnitude)
//        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
//        
//        let sizeFit = messageTextView.sizeThatFits(size)
//        
//        var estimatedFrame: CGRect!
//        
//        estimatedFrame = CGRect(x: 0.0, y: 0.0, width: sizeFit.width, height: sizeFit.height)
//        
//        if isAllEmoji(aString: messageText) {
//            // TODO: Fix the emoji
//            
//            
//            estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: TEXT_VIEW_FONT], context: nil)
//            log.info("emoji text: \(messageText) and frame: \(estimatedFrame)")
//        } else {
//            estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: TEXT_VIEW_FONT], context: nil)
//            log.info("normal text: \(messageText) and frame: \(estimatedFrame)")
//            
//        }
//
//        // Bunch of math going here: No need to tune these numbers, they look fine on all screens
//        
//        if !self.message.isSentByYou {
//            
//            // Message on left side
//            
//            self.profileImageView.isHidden = false
//            self.messageTextView.textColor = UIColor.black
//            
//            if isLastInChain {
//                // Apply tail
//                self.messageTextView.frame = CGRect(x: 45 + 8, y: 3, width: estimatedFrame.width + 32, height: estimatedFrame.height + 16)
//                self.textBubbleView.frame = CGRect(x: 45 - 8, y: 0, width: estimatedFrame.width + 32 + 8, height: estimatedFrame.height + 16 + 8)
//                self.bubbleImageView.backgroundColor = UIColor.clear
//                self.bubbleImageView.image = BUBBLE_RECIPIENT_IMAGE
//                self.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
//            } else {
//                self.messageTextView.frame = CGRect(x: 45 + 8, y: 0, width: estimatedFrame.width + 32, height: estimatedFrame.height + 16)
//                self.bubbleImageView.image = nil
//                self.textBubbleView.frame = CGRect(x: 45, y: 2, width: estimatedFrame.width + 32 + 8, height: estimatedFrame.height + 16)
//                self.bubbleImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
//            }
//        } else {
//            
//            // Message on right side
//            
//            self.profileImageView.isHidden = true
//            self.messageTextView.textColor = UIColor.white
//            
//            if isLastInChain {
//                // Apply tail
//                self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 3, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
//                self.bubbleImageView.backgroundColor = UIColor.clear
//                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: -1, width: estimatedFrame.width + 20 + 8 + 8, height: estimatedFrame.height + 16 + 8)
//                self.bubbleImageView.image = BUBBLE_ME_IMAGE
//                self.bubbleImageView.tintColor = GREEN_UICOLOR
//            } else {
//                self.messageTextView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 16 - 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
//                self.bubbleImageView.image = nil
//                self.textBubbleView.frame = CGRect(x: viewWidth - estimatedFrame.width - 16 - 8 - 16 - 8, y: 0, width: estimatedFrame.width + 20 + 8, height: estimatedFrame.height + 16)
//                self.bubbleImageView.backgroundColor = GREEN_UICOLOR
//            }
//        }
//        self.messageTextView.isScrollEnabled = false
    }
    
    func notifyControllerToExpand(tap: UITapGestureRecognizer) {
        self.shouldExpand = true
        NotificationCenter.default.post(name: NOTIF_EXPANDCHATCELL, object: nil)
    }
    
}
