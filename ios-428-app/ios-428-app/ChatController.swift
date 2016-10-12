//
//  ChatController.swift
//  ios-428-app
//
//  Controller for the 1-1 user chat screen. Note that this class is a bit long because of the necessary interplay 
//  between the different views, i.e. input container and collection views.
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ChatController: UIViewController, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    /** CONSTANTS **/
    fileprivate let CELL_ID = "chatCell"
    fileprivate let CELL_HEADER_ID = "chatHeaderView"
    fileprivate let SECTION_HEADER_HEIGHT: CGFloat = 30.0
    
    /** DATA **/
    fileprivate var messages: [Message]? // All messages
    fileprivate var messagesInTimeBuckets: [[Message]]? // Messages separated into buckets of time (at least 1 hour apart)
    fileprivate var timeBucketHeaders: [Date]? // Headers of time buckets, must have same length as messagesInTimeBuckets

    /** HEIGHTS AND CONSTRAINTS **/
    // Adjusted with multiple lines of text
    fileprivate var textViewHeight: CGFloat = 0.0
    fileprivate var inputContainerHeightConstraint: NSLayoutConstraint!
    // Adjusted for keyboard
    fileprivate var bottomConstraintForInput: NSLayoutConstraint!
    fileprivate var topConstraintForCollectionView: NSLayoutConstraint!
    
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
        // Scroll collection view to the bottom to most recent message upon first entering screen
        UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.scrollToLastItemInCollectionView(animated: false)
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterObservers()
    }
    
    // MARK: Process messages into buckets based on hourly time intervals
    
    // Function used for testing of buckets
    fileprivate func printMessagesArr() {
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
    
    // This function is called to reset the input container after handleSend is successful
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
        self.sendButton.isEnabled = !textView.text.trim().isEmpty // Disallow send when only newlines and spaces
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
                self.inputContainerHeightConstraint.constant = newHeight + 12.0 // Expand input container
                self.topConstraintForCollectionView.constant -= abs(newHeight - self.textViewHeight) // Shift collection view up
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
    
    fileprivate lazy var sendButton: UIButton = {
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
        messageInputContainerView.addConstraintsWithFormat("V:[v0]-7-|", views: sendButton)
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
                self.messages?.append(message)
                self.bucketMessagesIntoTime()
                self.collectionView.reloadData()
                self.scrollToLastItemInCollectionView()
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
            
            // Find bottom of collection view
            let lastSection = self.timeBucketHeaders!.count - 1
            let lastRow = self.messagesInTimeBuckets![lastSection].count - 1
            let indexPath = IndexPath(item: lastRow, section: lastSection)
            let attributes = self.collectionView.layoutAttributesForItem(at: indexPath)!
            let frame: CGRect = self.collectionView.convert(attributes.frame, to: collectionView.superview)
            let bottomOfCollectionView = frame.maxY
            
            // Compare it with top of input container
            let topOfInput = self.view.bounds.maxY - keyboardViewEndFrame.height - self.messageInputContainerView.bounds.height
            
            let isKeyboardBlockingCollection = bottomOfCollectionView >= topOfInput
            let distanceShifted = min(keyboardViewEndFrame.height, abs(bottomOfCollectionView - topOfInput + SECTION_HEADER_HEIGHT))
            
            // Also shift the input container's frame so that the input moves smoothly with keyboard
            // Bottom constraint for input has to also be shifted if not the input container will be expanded upon just shifting frame
            if isKeyboardShowing {
                self.scrollToLastItemInCollectionView()
                UIView.animate(withDuration: animationDuration, animations: {
                    self.messageInputContainerView.frame.origin.y -= keyboardViewEndFrame.height
                    self.bottomConstraintForInput.constant = -keyboardViewEndFrame.height
                    self.topConstraintForCollectionView.constant = isKeyboardBlockingCollection ? -distanceShifted : 0
                })
            } else {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.messageInputContainerView.frame.origin.y += keyboardViewEndFrame.height
                    self.bottomConstraintForInput.constant = 0
                    self.topConstraintForCollectionView.constant = 0
                })
            }
        }
    }
    
    // MARK: Collection view
    
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
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
        let layout = UICollectionViewFlowLayout()
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: SECTION_HEADER_HEIGHT)
        self.collectionView.setCollectionViewLayout(layout, animated: false)
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -SECTION_HEADER_HEIGHT, right: 0) // Fix adjustScrollInsets bottom padding
        self.collectionView.register(ChatCell.self, forCellWithReuseIdentifier: CELL_ID)
        self.collectionView.register(ChatHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CELL_HEADER_ID)
        self.view.addSubview(collectionView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        self.view.addConstraintsWithFormat("V:[v0]", views: collectionView)
        self.topConstraintForCollectionView = NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0)
        self.view.addConstraint(self.topConstraintForCollectionView)
        // Panning on collection view keeps keyboard
        let panToKeepKeyboardRecognizer = UIPanGestureRecognizer(target: self, action: #selector(keepKeyboard))
        panToKeepKeyboardRecognizer.delegate = self
        self.collectionView.addGestureRecognizer(panToKeepKeyboardRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func keepKeyboard(gestureRecognizer: UIPanGestureRecognizer) {
        self.inputTextView.endEditing(true)
    }
    
    fileprivate func scrollToLastItemInCollectionView(animated: Bool = true) {
        if self.timeBucketHeaders != nil && self.messagesInTimeBuckets != nil && self.timeBucketHeaders!.count > 0 && self.messagesInTimeBuckets!.count > 0 {
            let lastSection = self.timeBucketHeaders!.count - 1
            let lastRow = self.messagesInTimeBuckets![lastSection].count - 1
            let indexPath = IndexPath(item: lastRow, section: lastSection)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let count = self.timeBucketHeaders?.count {
            return count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let chatHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CELL_HEADER_ID, for: indexPath) as! ChatHeaderView
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ChatCell
        let message = self.messagesInTimeBuckets?[indexPath.section][indexPath.row]
        cell.configureCell(messageObj: message, viewWidth: view.frame.width)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let messageText = messagesInTimeBuckets?[indexPath.section][indexPath.row].text {
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 16)
        }
        return CGSize(width: view.frame.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Padding around section headers
        return UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    }

}
