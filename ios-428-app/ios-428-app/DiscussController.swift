//
//  DiscussController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class DiscussController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /** CONSTANTS **/
    fileprivate let CELL_ID = "topicChatCell"
    fileprivate let CELL_HEADER_ID = "topicChatHeaderView"
    fileprivate let SECTION_HEADER_HEIGHT: CGFloat = 30.0
    
    /** DATA **/
    fileprivate var messages: [TopicMessage] = [TopicMessage]() // All messages
    fileprivate var messagesInTimeBuckets: [[TopicMessage]] = [[TopicMessage]]() // Messages separated into buckets of time (at least 1 hour apart)
    fileprivate var messageIsLastInChain: [[Bool]] = [[Bool]]() // If true, that means message is the last message sent in chain of messages by one user, so bubble will be attached
    fileprivate var timeBucketHeaders: [Date] = [Date]() // Headers of time buckets, must have same length as messagesInTimeBuckets
    
    /** HEIGHTS AND CONSTRAINTS **/
    // Adjusted with multiple lines of text
    fileprivate var textViewHeight: CGFloat = 0.0
    fileprivate var inputContainerHeightConstraint: NSLayoutConstraint!
    // Adjusted for keyboard
    fileprivate var bottomConstraintForInput: NSLayoutConstraint!
    fileprivate var topConstraintForCollectionView: NSLayoutConstraint!
    fileprivate var keyboardHeight: CGFloat = 216.0 // Default of 216.0, but reset the first time keyboard pops up
    
    var topic: Topic! {
        didSet {
            if let dateString = topic.dateString {
                self.navigationItem.title = dateString
                self.messages = topic.topicMessages
                self.bucketMessagesIntoTime()
                self.assembleMessageIsLastInChain()
            }
        }
    }
    
    // MARK: Prompt
    
    fileprivate func animatePrompt() {
        UIView.animate(withDuration: 0.25, delay: 0.3, animations: {
            self.promptExpandIcon.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            }) { (completed) in
                UIView.animate(withDuration: 0.1, animations: { 
                    self.promptExpandIcon.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    fileprivate lazy var promptLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.rightInset = 40.0
        label.backgroundColor = RED_UICOLOR
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.white
        label.textAlignment = .left
        label.numberOfLines = 2
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openDescription))
        tapGestureRecognizer.delegate = self
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGestureRecognizer)
        return label
    }()
    
    fileprivate let promptExpandIcon: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "expand"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.white
        return imageView
    }()
    
    func openDescription() {
        log.info("open description modal")
        let discussModalController = DiscussModalController()
        discussModalController.topic = self.topic
        discussModalController.modalPresentationStyle = .overFullScreen
        discussModalController.modalTransitionStyle = .crossDissolve
        self.present(discussModalController, animated: true, completion: nil)
    }
    
    // MARK: Open description modal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.white
        self.setupPromptView()
        self.setupCollectionView()
        self.setupInputComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.extendedLayoutIncludesOpaqueBars = true
        self.collectionView.isHidden = false
        self.registerObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        animatePrompt()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterObservers()
    }
    
    fileprivate func setupPromptView() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.lineBreakMode = .byTruncatingTail
        promptLabel.attributedText = NSMutableAttributedString(string: topic.prompt, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        
        view.addSubview(promptLabel)
        view.addSubview(promptExpandIcon)
        view.addConstraintsWithFormat("H:|[v0]|", views: promptLabel)
        view.addConstraintsWithFormat("H:[v0(20)]-8-|", views: promptExpandIcon)
        view.addConstraint(NSLayoutConstraint(item: promptLabel, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: promptExpandIcon, attribute: .centerY, relatedBy: .equal, toItem: promptLabel, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        view.addConstraintsWithFormat("V:[v0(60)]", views: promptLabel)
        view.addConstraintsWithFormat("V:[v0(20)]", views: promptExpandIcon)
        
    }
    
    // MARK: Chat
    
    // MARK: Process messages into buckets based on hourly time intervals
    
    fileprivate func bucketMessagesIntoTime() {
        if self.messages.count == 0 {
            return
        }
        // Sort messages such that earliest messages come first
        self.messages = self.messages.sorted{($0.date.timeIntervalSince1970) < ($1.date.timeIntervalSince1970)}
        self.messagesInTimeBuckets = [[TopicMessage]]()
        self.timeBucketHeaders = [Date]()
        var currentBucketTime: Date? = nil
        var currentBucketMessages: [TopicMessage] = [TopicMessage]()
        
        for i in 0...self.messages.count - 1 {
            let message = self.messages[i]
            if currentBucketTime == nil {
                currentBucketTime = message.date
                currentBucketMessages = [message]
            } else {
                let timeInterval = message.date.timeIntervalSince(currentBucketTime!)
                let hoursApart = timeInterval / (60.0 * 60.0)
                if hoursApart > 1.0 { // Start new bucket
                    self.messagesInTimeBuckets.append(currentBucketMessages)
                    self.timeBucketHeaders.append(currentBucketTime!)
                    currentBucketTime = message.date
                    currentBucketMessages = [message]
                } else { // Add to current bucket
                    currentBucketMessages.append(message)
                }
            }
            if i == self.messages.count - 1 { // Last message
                self.messagesInTimeBuckets.append(currentBucketMessages)
                self.timeBucketHeaders.append(currentBucketTime!)
            }
        }
    }
    
    fileprivate func assembleMessageIsLastInChain() {
        if self.messagesInTimeBuckets.count <= 0 {
            return
        }
        self.messageIsLastInChain = [[Bool]]()
        for i in 0...self.messagesInTimeBuckets.count - 1 {
            let section: [TopicMessage] = self.messagesInTimeBuckets[i]
            var chains = [Bool]()
            if section.count == 0 {
                log.error("[Error] No messages in bucket")
                self.messageIsLastInChain.append(chains)
                continue
            }
            if section.count >= 2 {
                for j in 0...section.count - 2 {
                    let m0: TopicMessage = section[j]
                    let m1: TopicMessage = section[j+1]
                    // Last in chain if next one is different from current
                    chains.append(!((m0.isSender && m1.isSender) || (!m0.isSender && !m1.isSender)))
                }
            }
            // End of row will be last in chain automatically
            chains.append(true)
            self.messageIsLastInChain.append(chains)
        }
    }
    
    // MARK: Input text view
    
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
                // Shift screen accordingly
                let diff = newHeight - self.textViewHeight
                if (self.isCollectionViewBlockingInput() && diff > 0) || (diff < 0 && self.topConstraintForCollectionView.constant < 0) {
                    // Need to shift upwards if content is blocked (First conditional) OR
                    // Only shift downwards if previously shifted upwards (Second conditional)
                    let frame = self.collectionView.contentInset
                    self.collectionView.contentInset = UIEdgeInsets(top: frame.top + diff, left: frame.left, bottom: frame.bottom, right: frame.right)
                    self.topConstraintForCollectionView.constant -= diff
                }
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
        if let text = inputTextView.text {
            // Trim text before sending
            let message = TopicMessage(tmid: "999", parentTid: "4", posterUid: "999", posterName: "Yihang", posterDisciplineImageName: "business", text: text.trim(), date: Date(), isSender: true)
            self.messages.append(message)
            self.bucketMessagesIntoTime()
            self.assembleMessageIsLastInChain()
            self.resetInputContainer()
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.scrollToLastItemInCollectionView()
        }
    }

    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(expandCell), name: NOTIF_EXPANDTOPICCELL, object: nil)
    }
    
    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_EXPANDTOPICCELL, object: nil)
    }
    
    fileprivate func isCollectionViewBlockingInput() -> Bool {
        // Find bottom of collection view
        let lastSection = self.timeBucketHeaders.count - 1
        if lastSection < 0 || lastSection >= self.messagesInTimeBuckets.count {
            return false
        }
        let lastRow = self.messagesInTimeBuckets[lastSection].count - 1
        let indexPath = IndexPath(item: lastRow, section: lastSection)
        let attributes = self.collectionView.layoutAttributesForItem(at: indexPath)!
        let frame: CGRect = self.collectionView.convert(attributes.frame, to: self.view)
        let bottomOfCollectionView = frame.maxY
        
        // Compare it with top of input container
        let topOfInput = self.view.bounds.maxY - keyboardHeight - self.messageInputContainerView.bounds.height
        
        return bottomOfCollectionView >= topOfInput
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            
            let isKeyboardShowing = notification.name != Notification.Name.UIKeyboardWillHide
            let keyboardViewEndFrame = view.convert(keyboardFrame, from: view.window)
            self.keyboardHeight = keyboardViewEndFrame.height
            
            // TODO: Shift screen up by a bit, while keyboard all the way when keyboard only covers part of cells
            //            let distanceShifted = min(keyboardViewEndFrame.height, abs(bottomOfCollectionView - topOfInput + SECTION_HEADER_HEIGHT))
            
            
            if isKeyboardShowing {
                self.scrollToLastItemInCollectionView()
                UIView.animate(withDuration: animationDuration, animations: {
                    if self.isCollectionViewBlockingInput() {
                        self.view.frame.origin.y = -keyboardViewEndFrame.height
                    } else {
                        self.bottomConstraintForInput.constant = -keyboardViewEndFrame.height
                    }
                })
            } else {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.view.frame.origin.y = 0
                    self.bottomConstraintForInput.constant = 0
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
        collectionView.showsVerticalScrollIndicator = true
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
        self.automaticallyAdjustsScrollViewInsets = false
        self.collectionView.contentInset = UIEdgeInsets(top: 8.0, left: 0, bottom: 0.8*SECTION_HEADER_HEIGHT, right: 0) // Fix top and bottom padding since automaticallyAdjustScrollViewInsets set to false
        
        self.collectionView.register(TopicChatCell.self, forCellWithReuseIdentifier: CELL_ID)
        self.collectionView.register(ChatHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CELL_HEADER_ID)
        
        self.view.addSubview(collectionView)
        
        self.view.addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        self.view.addConstraintsWithFormat("V:[v0]", views: collectionView)
        self.topConstraintForCollectionView = NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self.promptLabel, attribute: .bottom, multiplier: 1.0, constant: 0)
        self.view.addConstraint(self.topConstraintForCollectionView)
        
        // Panning on collection view keeps keyboard
        let panToKeepKeyboardRecognizer = UIPanGestureRecognizer(target: self, action: #selector(keepKeyboard))
        panToKeepKeyboardRecognizer.delegate = self
        self.collectionView.addGestureRecognizer(panToKeepKeyboardRecognizer)
        
        // Scroll collection view to the bottom to most recent message upon first entering screen
        UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.scrollToLastItemInCollectionView(animated: false)
        })
    }
    
    func keepKeyboard(gestureRecognizer: UIPanGestureRecognizer) {
        self.inputTextView.endEditing(true)
    }
    
    fileprivate func scrollToLastItemInCollectionView(animated: Bool = true) {
        if self.timeBucketHeaders.count > 0 && self.messagesInTimeBuckets.count > 0 {
            let lastSection = self.timeBucketHeaders.count - 1
            let lastRow = self.messagesInTimeBuckets[lastSection].count - 1
            let indexPath = IndexPath(item: lastRow, section: lastSection)
            let frame = self.collectionView.contentInset
            self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
            self.collectionView.layoutIfNeeded()
            self.collectionView.contentInset = frame
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.timeBucketHeaders.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let chatHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CELL_HEADER_ID, for: indexPath) as! ChatHeaderView
            chatHeaderView.date = self.timeBucketHeaders[indexPath.section]
            return chatHeaderView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messagesInTimeBuckets[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! TopicChatCell
        let message = self.messagesInTimeBuckets[indexPath.section][indexPath.row]
        let isLastInChain = self.messageIsLastInChain[indexPath.section][indexPath.row]
        cell.configureCell(messageObj: message, viewWidth: view.frame.width, isLastInChain: isLastInChain)
        return cell
    }
    
    
    private var cellTimeLabel = UILabel()
    private var tappedIndexPath: IndexPath?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = messagesInTimeBuckets[indexPath.section][indexPath.row]
        let messageText = message.text
        let messageDate = message.date
        
        let size = CGSize(width: 250, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
        let cellHeight = message.isSender ? estimatedFrame.height + 16 : estimatedFrame.height + 16 + 19
        if let cell = self.collectionView.cellForItem(at: indexPath) as? TopicChatCell {
            if cell.shouldExpand {
                self.cellTimeLabel.removeFromSuperview()
                let cellFrame = self.collectionView.convert(cell.frame, to: self.view)
                var yi = cellFrame.origin.y + cellFrame.height
                // Insert timeLabel here
                log.info("=====")
                log.info("\(self.tappedIndexPath)")
                yi += 10
                if tappedIndexPath == nil {
                    log.info("Indexpath nil")
                    tappedIndexPath = indexPath
                }
                else {
                    if indexPath.section > tappedIndexPath!.section || (indexPath.section == tappedIndexPath!.section && indexPath.row > tappedIndexPath!.row) {
                        log.info("Tapped below")
                        yi -= 24
                    } else if indexPath.section == tappedIndexPath!.section && indexPath.row == tappedIndexPath!.row {
                        // Clicked to hide
                        log.info("Hiding")
                        self.tappedIndexPath = nil
                        cell.shouldExpand = false
                        // Return with no expansion
                        return CGSize(width: view.frame.width, height: cellHeight)
                    }
                    tappedIndexPath = indexPath
                }
                
                let labelFrameInView = CGRect(x: 50, y: yi, width: self.view.frame.width - 80, height: 15)
                let labelFrame = self.view.convert(labelFrameInView, to: self.collectionView)
                cellTimeLabel = UILabel(frame: labelFrame)
                
                // Extract hh:mm a from time
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "h:mm a"
                let dateString = dateFormatter.string(from: messageDate)
                
                // Alignment based on who texted
                cellTimeLabel.textAlignment = message.isSender ? .right : .left
                cellTimeLabel.text = (message.isSender ? "Sent at " : "Received at ") + dateString
                
                cellTimeLabel.font = UIFont.systemFont(ofSize: 12.0)
                cellTimeLabel.textColor = UIColor.lightGray
                
                self.collectionView.addSubview(cellTimeLabel)
                cell.shouldExpand = false
                // Return with expansion
                return CGSize(width: view.frame.width, height: cellHeight + 24)
            }
        }
        // Return with no expansion
        return CGSize(width: view.frame.width, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Padding around section headers
        return UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    }
    
    func expandCell(notif: Notification) {
        // Called by TopicChatCell's messageTextView to invalidate layout
        UIView.animate(withDuration: 0.3) {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

}
