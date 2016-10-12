//
//  ChatController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ChatController: UIViewController, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    fileprivate var messages: [Message]? // All messages
    fileprivate var messagesInTimeBuckets: [[Message]]? // Messages separated into buckets of time (at least 1 hour apart)
    fileprivate var timeBucketHeaders: [Date]? // Headers of time buckets, must have same length as messagesInTimeBuckets
    fileprivate let cellId = "chatCell"
    fileprivate let cellHeaderId = "chatHeaderView"
    
    // Adjusted with multiple lines of text
    fileprivate var textViewHeight: CGFloat = 0.0
    fileprivate var inputContainerHeightConstraint: NSLayoutConstraint!
    // Adjusted for keyboard
    fileprivate var bottomConstraintForInput: NSLayoutConstraint!

    var friend: Friend? {
        didSet { // Set from didSelect in ConnectionsController
            self.navigationItem.title = self.friend?.name
            self.messages = friend?.messages?.allObjects as? [Message]
            self.bucketMessagesIntoTime()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        printMessagesArr()
        self.setupCollectionView()
        self.setupInputComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        self.registerObservers()
        // Scroll collection view to the bottom to most recent message
        UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                if self.timeBucketHeaders != nil && self.messagesInTimeBuckets != nil && self.timeBucketHeaders!.count > 0 && self.messagesInTimeBuckets!.count > 0 {
                    let lastSection = self.timeBucketHeaders!.count - 1
                    let lastRow = self.messagesInTimeBuckets![lastSection].count - 1
                    let indexPath = IndexPath(item: lastRow, section: lastSection)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterObservers()
    }
    
    // MARK: Process messages into buckets based on hourly time intervals
    
    func printMessagesArr() {
        for messages in messagesInTimeBuckets! {
            log.info("-Bucket-")
            for message in messages {
                log.info(message.text)
            }
        }
    }
    
    fileprivate func bucketMessagesIntoTime() {
        if self.messages == nil || self.messages!.count == 0 {
            return
        }
        // Sort messages such that earliest messages come first
        self.messages = self.messages?.sorted{($0.date!.timeIntervalSince1970) < ($1.date!.timeIntervalSince1970)}
        self.messagesInTimeBuckets = [[Message]]()
        self.timeBucketHeaders = [Date]()
        var currentBucketTime: Date? = nil
        var currentBucketMessages: [Message] = [Message]()
        
        for i in 0...self.messages!.count - 1 {
            let message = self.messages![i]
            if message.date == nil {
                log.error("Nil time for message: \(message)")
                continue
            }
            if currentBucketTime == nil {
                currentBucketTime = message.date!
                currentBucketMessages = [message]
            } else {
                let timeInterval = message.date!.timeIntervalSince(currentBucketTime!)
                let hoursApart = timeInterval / (60.0 * 60.0)
                if hoursApart > 1.0 { // Start new bucket
                    self.messagesInTimeBuckets?.append(currentBucketMessages)
                    self.timeBucketHeaders?.append(currentBucketTime!)
                    currentBucketTime = message.date!
                    currentBucketMessages = [message]
                } else { // Add to current bucket
                    currentBucketMessages.append(message)
                }
            }
            if i == self.messages!.count - 1 { // Last message
                self.messagesInTimeBuckets?.append(currentBucketMessages)
                self.timeBucketHeaders?.append(currentBucketTime!)
            }
        }
    }
    
    // MARK: Input text view
    
    // Input container is reset after handleSend is successful
    fileprivate func resetInputContainer() {
        self.textViewHeight = 0.0
        self.inputContainerHeightConstraint.constant = 45.0
        self.view.layoutIfNeeded()
        self.sendButton.isEnabled = false
        inputTextView.text = nil
        self.placeholderLabel.isHidden = false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Disable send and show placeholder when there is no text
        self.sendButton.isEnabled = !textView.text.trim().isEmpty
        self.placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Expansion of text view upon newline
        let size = textView.bounds.size
        let newHeight = textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude)).height
        if self.textViewHeight == 0 {
            self.textViewHeight = newHeight
            return
        }
        if self.textViewHeight != newHeight {
            // Change height of message input container only if container doesn't cover too much of screen
            let screenHeight = UIScreen.main.bounds.height
            if newHeight < 0.2 * screenHeight {
                self.inputContainerHeightConstraint.constant = newHeight + 12.0
                // TODO: Instead change top constraint of collectionView?
//                self.collectionView.frame.origin.y -= 14.0
//                self.collectionView.layoutIfNeeded()
                self.view.layoutIfNeeded()
            } else {
                textView.flashScrollIndicators()
            }
        }
        self.textViewHeight = newHeight
        
    }
    
    // MARK: Input
    
    fileprivate let messageInputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    fileprivate let inputTextView: UITextView = {
       let textView = UITextView()
        textView.textColor = UIColor.black
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.tintColor = GREEN_UICOLOR
        return textView
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.setTitleColor(GREEN_UICOLOR, for: .normal)
        button.setTitleColor(GRAY_UICOLOR, for: .disabled)
        button.titleLabel?.font = FONT_HEAVY_LARGE
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    fileprivate let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Type a Message..."
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor(white: 0, alpha: 0.15)
        label.sizeToFit()
        label.isHidden = false
        return label
    }()
    
    fileprivate func setupInputComponents() {
        // View
        view.addSubview(messageInputContainerView)
        view.addConstraintsWithFormat("H:|[v0]|", views: messageInputContainerView)
        
        inputContainerHeightConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 45)
        view.addConstraint(inputContainerHeightConstraint)
        view.addConstraintsWithFormat("V:[v0]", views: messageInputContainerView)
        bottomConstraintForInput = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraintForInput)
        
        // Message input container
        self.inputTextView.delegate = self
        self.inputTextView.enablesReturnKeyAutomatically = true
        messageInputContainerView.addSubview(inputTextView)
        messageInputContainerView.addSubview(sendButton)
        
        let topBorderView = UIView()
        topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        messageInputContainerView.addSubview(topBorderView)
        
        messageInputContainerView.addConstraintsWithFormat("H:|-5-[v0][v1(60)]-5-|", views: inputTextView, sendButton)
        messageInputContainerView.addConstraintsWithFormat("V:|-5-[v0]|", views: inputTextView)
        messageInputContainerView.addConstraintsWithFormat("V:[v0]-8-|", views: sendButton)
        messageInputContainerView.addConstraintsWithFormat("H:|[v0]|", views: topBorderView)
        messageInputContainerView.addConstraintsWithFormat("V:|[v0(0.5)]", views: topBorderView)
        
        // Placeholder
        self.inputTextView.addSubview(self.placeholderLabel)
        self.placeholderLabel.frame.origin = CGPoint(x: 8, y: (self.inputTextView.font?.pointSize)! / 2)
        self.placeholderLabel.isHidden = !self.inputTextView.text.isEmpty
        
        // Add bottom of collection view contraint to top of input container
        let bottomConstraintForCollectionView = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: messageInputContainerView, attribute: .top, multiplier: 1.0, constant: 0)
        view.addConstraint(bottomConstraintForCollectionView)
    }
    
    func handleSend() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = delegate.persistentContainer.viewContext
        if let friend = friend, let text = inputTextView.text {
            // Trim text before sending
            let message = ConnectionsController.createMessageForFriend(friend, text: text.trim(), minutesAgo: 0, context: context, isSender: true)
            do {
                try context.save()
                messages?.append(message)
                self.bucketMessagesIntoTime()
                let insertionIndexPath = IndexPath(item: messages!.count - 1, section: 0)
                collectionView.insertItems(at: [insertionIndexPath])
                collectionView.scrollToItem(at: insertionIndexPath, at: .bottom, animated: true)
                self.resetInputContainer()
            } catch let err {
                print(err)
            }
        }
    }
    
    // MARK: Keyboard
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            let isKeyboardShowing = notification.name != Notification.Name.UIKeyboardWillHide
            let keyboardViewEndFrame = view.convert(keyboardFrame, from: view.window)
            
            let lastSection = self.timeBucketHeaders!.count - 1
            let lastRow = self.messagesInTimeBuckets![lastSection].count - 1
            let indexPath = IndexPath(item: lastRow, section: lastSection)
            let attributes = self.collectionView.layoutAttributesForItem(at: indexPath)!
            let frame: CGRect = self.collectionView.convert(attributes.frame, to: collectionView.superview)
            
            let bottomOfCollectionView = frame.maxY
            
            let topOfInput = self.view.bounds.maxY - keyboardViewEndFrame.height - self.messageInputContainerView.bounds.height
            
            log.info("Bottom of collection view: \(bottomOfCollectionView), Top of input: \(topOfInput)")
            
            let isKeyboardBlockingCollection = bottomOfCollectionView >= topOfInput
            
            if isKeyboardBlockingCollection && isKeyboardShowing {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.view.frame.origin.y = -keyboardViewEndFrame.height
                })
            } else if !isKeyboardBlockingCollection && isKeyboardShowing {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.messageInputContainerView.frame.origin.y -= keyboardViewEndFrame.height
                    self.bottomConstraintForInput.constant = -keyboardViewEndFrame.height
                })
            } else if isKeyboardBlockingCollection && !isKeyboardShowing {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.view.frame.origin.y = 0
                })
            } else {
                UIView.animate(withDuration: animationDuration, animations: {
                    log.info("hi")
                    self.messageInputContainerView.frame.origin.y += keyboardViewEndFrame.height
                    self.bottomConstraintForInput.constant = 0
                })
            }
        }
    }
    
    // MARK: Collection view
    
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 30)
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    private func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.bounces = true
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.register(ChatCell.self, forCellWithReuseIdentifier: cellId)
        self.collectionView.register(ChatHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: cellHeaderId)
        self.view.addSubview(collectionView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        self.view.addConstraintsWithFormat("V:|[v0]", views: collectionView)
        // Tapping anywhere on collection view keeps keyboard
        let tapToKeepKeyboardRecognizer = UITapGestureRecognizer(target: self, action: #selector(keepKeyboard))
        self.collectionView.addGestureRecognizer(tapToKeepKeyboardRecognizer)
    }
    
    func keepKeyboard(gestureRecognizer: UITapGestureRecognizer) {
        self.inputTextView.endEditing(true)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let count = self.timeBucketHeaders?.count {
            return count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let chatHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: cellHeaderId, for: indexPath) as! ChatHeaderView
            chatHeaderView.date = self.timeBucketHeaders?[indexPath.section]
            return chatHeaderView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = self.messagesInTimeBuckets?[section].count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatCell
        cell.messageTextView.isScrollEnabled = true
        cell.messageTextView.text = self.messagesInTimeBuckets?[indexPath.section][indexPath.row].text
        if let message = self.messagesInTimeBuckets?[indexPath.section][indexPath.row], let messageText = message.text, let profileImageName = message.friend?.profileImageName {
            cell.profileImageView.image = UIImage(named: profileImageName)
            
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: FONT_MEDIUM_MID], context: nil)
            if !message.isSender {
                cell.messageTextView.frame = CGRect(x: 45 + 8, y: -4, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
                cell.textBubbleView.frame = CGRect(x: 45 - 8, y: -4, width: estimatedFrame.width + 16 + 8 + 8, height: estimatedFrame.height + 16 + 6)
                cell.profileImageView.isHidden = false
                cell.bubbleImageView.image = ChatCell.grayBubbleImage
                cell.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
                cell.messageTextView.textColor = UIColor.black
            } else {
                cell.messageTextView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 16 - 8, y: -4, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
                cell.textBubbleView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 8 - 16 - 8, y: -4, width: estimatedFrame.width + 16 + 8 + 8, height: estimatedFrame.height + 16 + 6)
                cell.profileImageView.isHidden = true
                cell.bubbleImageView.image = ChatCell.greenBubbleImage
                cell.bubbleImageView.tintColor = GREEN_UICOLOR
                cell.messageTextView.textColor = UIColor.white
            }
            
        }
        cell.messageTextView.sizeToFit()
        cell.messageTextView.isScrollEnabled = false
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let messageText = messagesInTimeBuckets?[indexPath.section][indexPath.row].text {
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: FONT_MEDIUM_MID], context: nil) // TODO: Change this to System font
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 16)
        }
        return CGSize(width: view.frame.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // TODO: Think of how to fix big footer gap
        return UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.inputTextView.endEditing(true)
    }
}
