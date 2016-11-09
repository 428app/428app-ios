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
import Firebase

class ChatController: UIViewController, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    /** FIREBASE **/
    fileprivate var firebaseRefsAndHandles: [(FIRDatabaseReference, FIRDatabaseHandle)] = []
    fileprivate var numMessages: UInt = 50 // Increases as user scrolls to top of collection view
    fileprivate let NUM_INCREMENT: UInt = 50 // Downloads 50 messages per scroll
    fileprivate var countdownToAddLimitAfterAddingMessage: UInt = 10 // Reobserve on every 10 messages added
    
    /** CONSTANTS **/
    fileprivate let CELL_ID = "chatCell"
    fileprivate let CELL_HEADER_ID = "chatHeaderView"
    fileprivate let SECTION_HEADER_HEIGHT: CGFloat = 30.0
    
    /** DATA **/
    fileprivate var messages: [Message] = [Message]() // All messages
    fileprivate var messagesInTimeBuckets: [[Message]] = [[Message]]() // Messages separated into buckets of time (at least 1 hour apart)
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
    
    var connection: Connection! {
        didSet {
            let limit = connectionUidToMessageLimit[self.connection.uid]
            if limit != nil {
                self.numMessages = limit!
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupFirebase()
        self.view.backgroundColor = UIColor.white
        self.setupNavigationBar()
        self.setupCollectionView()
        self.setupInputComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.navigationBar.isHidden = false
        self.collectionView.isHidden = false
        self.registerObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Retain numMessages limit when user reopens this chat
        connectionUidToMessageLimit[self.connection.uid] = self.numMessages
        self.unregisterObservers()
    }
    
    deinit {
        for (ref, handle) in firebaseRefsAndHandles {
            ref.removeObserver(withHandle: handle)
        }
    }
    
    // MARK: Firebase
    
    func loadMoreMessages() {
        numMessages += NUM_INCREMENT
        self.reobserveMessages(isReobserved: true)
    }
    
    fileprivate func reobserveMessages(isReobserved: Bool) {
        for (ref, handle) in firebaseRefsAndHandles {
            ref.removeObserver(withHandle: handle)
        }
        self.firebaseRefsAndHandles.append(DataService.ds.observeChatMessages(connection: self.connection, limit: self.numMessages, completed: { (isSuccess, updatedConnection) in
            if (!isSuccess || updatedConnection == nil) {
                if (isReobserved) {
                    // Rewind numMessages
                    self.numMessages -= self.NUM_INCREMENT
                }
                log.error("[Error] Can't pull chats for individual connection")
                return
            }
            log.info("Messages updated")
            self.messages = updatedConnection!.messages
            self.organizeMessages()
            self.collectionView.reloadData()
            self.refreshControl.endRefreshing()
        }))
    }
    
    fileprivate lazy var refreshControl: UIRefreshControl = {
       let control = UIRefreshControl()
        control.tintColor = UIColor.white
        control.backgroundColor = GREEN_UICOLOR
        control.attributedTitle = NSAttributedString(string: "Pull to load more messages", attributes: [NSFontAttributeName: FONT_HEAVY_SMALL, NSForegroundColorAttributeName: UIColor.white])
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()
    
    func setupFirebase() {
        // Also setup refresh control
        collectionView.addSubview(self.refreshControl)
        self.reobserveMessages(isReobserved: false)
    }
    
    // MARK: Process messages into buckets based on hourly time intervals
    
    fileprivate func organizeMessages() {
        self.bucketMessagesIntoTime()
        self.assembleMessageIsLastInChain()
    }
    
    fileprivate func bucketMessagesIntoTime() {
        if self.messages.count == 0 {
            return
        }
        // Sort messages such that earliest messages come first
        self.messages = self.messages.sorted{($0.date.timeIntervalSince1970) < ($1.date.timeIntervalSince1970)}
        self.messagesInTimeBuckets = [[Message]]()
        self.timeBucketHeaders = [Date]()
        var currentBucketTime: Date? = nil
        var currentBucketMessages: [Message] = [Message]()
        
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
            let section: [Message] = self.messagesInTimeBuckets[i]
            var chains = [Bool]()
            if section.count == 0 {
                log.error("[Error] No messages in bucket")
                self.messageIsLastInChain.append(chains)
                continue
            }
            if section.count >= 2 {
                for j in 0...section.count - 2 {
                    let m0: Message = section[j]
                    let m1: Message = section[j+1]
                    // Last in chain if next one is different from current
                    chains.append(!((m0.isSentByYou && m1.isSentByYou) || (!m0.isSentByYou && !m1.isSentByYou)))
                }
            }
            // End of row will be last in chain automatically
            chains.append(true)
            self.messageIsLastInChain.append(chains)
        }
    }
    
    // MARK: Navigation bar
    
    fileprivate let navTitleView: UIButton = {
        let width = UIScreen.main.bounds.width
        let button = UIButton(frame: CGRect(x: width*0.25, y: 0, width: width*0.5, height: 30))
        return button
    }()
    
    func openProfile(button: UIButton) {
        // TODO: Fetch profile from server based on this connection id
        let controller = ProfileController()
        controller.profile = jennyprof
        controller.modalTransitionStyle = .coverVertical
        self.navigationController?.navigationBar.isHidden = true
        self.collectionView.isHidden = true
        self.present(controller, animated: true, completion: nil)
    }
    
    fileprivate let navLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let navButton: UIButton = {
       let button = UIButton()
        button.titleLabel?.font = FONT_HEAVY_LARGE
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(GREEN_UICOLOR, for: .highlighted)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    
    fileprivate let navDisciplineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    fileprivate func setupNavTitleView() {
        navButton.setTitle(self.connection.name, for: .normal)
        navButton.setTitleColor(UIColor.black, for: .normal)
        navDisciplineImageView.image = UIImage(named: self.connection.disciplineImageName)
        
        navTitleView.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
        navButton.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
        
        let navContainerView = UIView()
        navContainerView.translatesAutoresizingMaskIntoConstraints = false
        navTitleView.addSubview(navContainerView)
        navTitleView.addConstraint(NSLayoutConstraint(item: navContainerView, attribute: .centerX, relatedBy: .equal, toItem: navTitleView, attribute: .centerX, multiplier: 1.0, constant: 0))
        navTitleView.addConstraint(NSLayoutConstraint(item: navContainerView, attribute: .centerY, relatedBy: .equal, toItem: navTitleView, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        navContainerView.addSubview(navDisciplineImageView)
        navContainerView.addSubview(navButton)
        navContainerView.addConstraintsWithFormat("H:|[v0(20)]-8-[v1]|", views: navDisciplineImageView, navButton)
        navContainerView.addConstraintsWithFormat("V:|[v0(20)]", views: navDisciplineImageView)
        navContainerView.addConstraintsWithFormat("V:|-1-[v0(22)]|", views: navButton)
        self.navigationItem.titleView = navTitleView
    }
    
    fileprivate func setupNavigationBar() {
        let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpace.width = -6.0
        let moreButton = UIBarButtonItem(image: #imageLiteral(resourceName: "more"), style: .plain, target: self, action: #selector(handleNavMore))
        self.navigationItem.rightBarButtonItems = [negativeSpace, moreButton]
        self.setupNavTitleView()
    }
    
    func handleNavMore() {
        // Bring up alert controller to Mute or Report person
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tintColor = GREEN_UICOLOR
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let muteAction = UIAlertAction(title: "Mute Notifications", style: .default) { (action) in
            // TODO: Mute user's notifications
        }
        let reportAction = UIAlertAction(title: "Report \(self.connection.name)", style: .default) { (action) in
            // Report user
        }
        alertController.addAction(muteAction)
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
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
            
            // Reobserve every 10 messages
            self.countdownToAddLimitAfterAddingMessage -= 1
            if self.countdownToAddLimitAfterAddingMessage <= 0 {
                self.countdownToAddLimitAfterAddingMessage = 10
                self.numMessages += 10
                self.reobserveMessages(isReobserved: true)
            }
            
            DataService.ds.addChatMessage(connection: connection, text: text.trim(), completed: { (isSuccess, updatedConnection) in
                if !isSuccess || updatedConnection == nil {
                    // Reset countdown if failure to add
                    self.countdownToAddLimitAfterAddingMessage += 1
                    self.countdownToAddLimitAfterAddingMessage %= 10
                    
                    log.error("[Error] Message failed to be posted")
                    showErrorAlert(vc: self, title: "Error", message: "Could not send message. Please try again.")
                    return
                }
                self.organizeMessages()
                self.resetInputContainer()
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
                self.scrollToLastItemInCollectionView()
            })
        }
    }
    
    // MARK: Keyboard
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(expandCell), name: NOTIF_EXPANDCHATCELL, object: nil)
    }
    
    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_EXPANDCHATCELL, object: nil)
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
        self.collectionView.contentInset = UIEdgeInsets(top: (self.navigationController?.navigationBar.frame.height)! + 0.7*SECTION_HEADER_HEIGHT, left: 0, bottom: 0.8*SECTION_HEADER_HEIGHT, right: 0) // Fix top and bottom padding since automaticallyAdjustScrollViewInsets set to false
        
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
        
        // Scroll collection view to the bottom to most recent message upon first entering screen
        UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.scrollToLastItemInCollectionView(animated: false)
        })
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ChatCell
        cell.request?.cancel()
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
        if let cell = self.collectionView.cellForItem(at: indexPath) as? ChatCell {
            
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
                        return CGSize(width: view.frame.width, height: estimatedFrame.height + 16)
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
                cellTimeLabel.textAlignment = message.isSentByYou ? .right : .left
                cellTimeLabel.text = (message.isSentByYou ? "Sent at " : "Received at ") + dateString
                
                cellTimeLabel.font = UIFont.systemFont(ofSize: 12.0)
                cellTimeLabel.textColor = UIColor.lightGray
                
                self.collectionView.addSubview(cellTimeLabel)
                cell.shouldExpand = false
                // Return with expansion
                return CGSize(width: view.frame.width, height: estimatedFrame.height + 40)
            }
        }
        // Return with no expansion
        return CGSize(width: view.frame.width, height: estimatedFrame.height + 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Padding around section headers
        return UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    }
    
    func expandCell(notif: Notification) {
        // Called by ChatCell's messageTextView to invalidate layout
        UIView.animate(withDuration: 0.3) {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}
