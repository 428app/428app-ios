//
//  ChatClassroomController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ChatClassroomController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /** CONSTANTS **/
    fileprivate let CELL_ID = "classroomChatCell"
    fileprivate let CELL_HEADER_ID = "classroomChatHeaderView"
    fileprivate let SECTION_HEADER_HEIGHT: CGFloat = 30.0
    
    /** DATA **/
    fileprivate var messages: [ClassroomMessage] = [ClassroomMessage]() // All messages
    fileprivate var messagesInTimeBuckets: [[ClassroomMessage]] = [[ClassroomMessage]]() // Messages separated into buckets of time (at least 1 hour apart)
    fileprivate var messageIsLastInChain: [[Bool]] = [[Bool]]() // If true, that means message is the last message sent in chain of messages by one user, so bubble will be attached
    fileprivate var timeBucketHeaders: [Date] = [Date]() // Headers of time buckets, must have same length as messagesInTimeBuckets
    
    /** HEIGHTS AND CONSTRAINTS **/
    // Adjusted with multiple lines of text
    fileprivate var textViewHeight: CGFloat = 0.0
    fileprivate var inputContainerHeightConstraint: NSLayoutConstraint!
    // Adjusted for keyboard
    fileprivate var bottomConstraintForInput: NSLayoutConstraint!
    fileprivate var TOP_GAP: CGFloat = 0.0 // Default value of topConstraintForCollectionView, intially set in setupCollectionView
    fileprivate var topConstraintForCollectionView: NSLayoutConstraint!
    fileprivate var keyboardHeight: CGFloat = 216.0 // Default of 216.0, but reset the first time keyboard pops up
    
    let interactor = Interactor() // Used for transitioning to and from ProfileController
    
    var classroom: Classroom! {
        didSet {
            self.navigationItem.title = classroom.title
            self.questionBanner.text = "Read Question \(classroom.questionNum) here"
            self.messages = classroom.classroomMessages
            self.bucketMessagesIntoTime()
            self.assembleMessageIsLastInChain()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.setupNavigationBar()
        self.setupPromptView()
        self.setupCollectionView()
        self.setupInputComponents()
        self.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.extendedLayoutIncludesOpaqueBars = true
        self.tabBarController?.tabBar.isHidden = true
        self.registerObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        self.unregisterObservers()
    }
    
    // MARK: Firebase
    
    func loadData() {
        showRatingAlert()
    }
    
    // MARK: Navigation
    
    fileprivate func setupNavigationBar() {
        let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpace.width = -6.0
        let moreButton = UIBarButtonItem(image: #imageLiteral(resourceName: "more"), style: .plain, target: self, action: #selector(handleNavMore))
        self.navigationItem.rightBarButtonItems = [negativeSpace, moreButton]
    }
    
    func handleNavMore() {
        // Bring up alert controller to view classmates, answers or ratings
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tintColor = GREEN_UICOLOR
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let classmatesAction = UIAlertAction(title: "Classmates", style: .default) { (action) in
            let controller = ClassmatesController(collectionViewLayout: UICollectionViewFlowLayout())
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
            controller.classmates = self.classroom.members
            self.navigationController?.pushViewController(controller, animated: true)
        }
        let answersAction = UIAlertAction(title: "Answers", style: .default) { (action) in
            let controller = AnswersController()
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
            controller.questions = self.classroom.questions
            self.navigationController?.pushViewController(controller, animated: true)
        }
        let ratingsAction = UIAlertAction(title: "Ratings", style: .default) { (action) in
            self.launchRatingsController()
        }
        // TODO: Disable this if memberHasRated is nil
        ratingsAction.isEnabled = true
        alertController.addAction(classmatesAction)
        alertController.addAction(answersAction)
        alertController.addAction(ratingsAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Question banner on top
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    fileprivate lazy var questionBanner: UILabel = {
        let label = UILabel()
        label.backgroundColor = GRAY_UICOLOR
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.numberOfLines = 1
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openDescription))
        tapGestureRecognizer.delegate = self
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGestureRecognizer)
        return label
    }()
    
    func openDescription() {
        let modalController = ModalQuestionController()
        modalController.classroom = self.classroom
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .crossDissolve
        self.present(modalController, animated: true, completion: nil)
    }
    
    fileprivate func setupPromptView() {
        view.addSubview(questionBanner)
        view.addConstraintsWithFormat("H:|[v0]|", views: questionBanner)
        if let navHeight = navigationController?.navigationBar.frame.height {
           view.addConstraintsWithFormat("V:|-\(navHeight * 1.45)-[v0(40)]", views: questionBanner)
        } else {
            view.addConstraint(NSLayoutConstraint(item: questionBanner, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0))
           view.addConstraintsWithFormat("V:[v0(60)]", views: questionBanner)
        }
    }
    
    // MARK: Rating alert
    
    fileprivate func showRatingAlert() {
        let alertController = RatingsAlertController()
        alertController.classroom = self.classroom
        alertController.modalPresentationStyle = .overFullScreen
        alertController.modalTransitionStyle = .crossDissolve
        self.present(alertController, animated: true, completion: nil)
    }
    
    func launchRatingsController() {
        // TODO: Read rating type from server then load
        let controller = RatingsController()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        controller.results = self.classroom.results
        controller.ratings = self.classroom.ratings
        controller.classmates = self.classroom.members
        controller.ratingType = self.classroom.hasRatingType
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: No messages view
    
    fileprivate let emptyPlaceholderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4))
        view.isHidden = true
        return view
    }()
    
    fileprivate let minionImage: UIImageView = {
        let image = #imageLiteral(resourceName: "minion")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let noMessagesLbl: UIView = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "Don't be shy. Speak."
        return label
    }()
    
    fileprivate func setupEmptyPlaceholderView() {
        
        self.emptyPlaceholderView.isHidden = self.messages.count != 0 // TODO: This will be shifted to the Firebase call
        
        self.collectionView.addSubview(self.emptyPlaceholderView)
        self.emptyPlaceholderView.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.05 * self.view.frame.height)
        self.emptyPlaceholderView.addSubview(minionImage)
        self.emptyPlaceholderView.addSubview(noMessagesLbl)
        self.emptyPlaceholderView.addConstraintsWithFormat("H:[v0(60)]", views: minionImage)
        self.emptyPlaceholderView.addConstraint(NSLayoutConstraint(item: minionImage, attribute: .centerX, relatedBy: .equal, toItem: self.emptyPlaceholderView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        self.emptyPlaceholderView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: noMessagesLbl)
        
        self.emptyPlaceholderView.addConstraintsWithFormat("V:|-8-[v0(60)]-5-[v1]", views: minionImage, noMessagesLbl)
    }
    
    // MARK: Chat
    
    // MARK: Process messages into buckets based on hourly time intervals
    
    fileprivate func bucketMessagesIntoTime() {
        if self.messages.count == 0 {
            return
        }
        // Sort messages such that earliest messages come first
        self.messages = self.messages.sorted{($0.date.timeIntervalSince1970) < ($1.date.timeIntervalSince1970)}
        self.messagesInTimeBuckets = [[ClassroomMessage]]()
        self.timeBucketHeaders = [Date]()
        var currentBucketTime: Date? = nil
        var currentBucketMessages: [ClassroomMessage] = [ClassroomMessage]()
        
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
            let section: [ClassroomMessage] = self.messagesInTimeBuckets[i]
            var chains = [Bool]()
            if section.count == 0 {
                log.error("[Error] No messages in bucket")
                self.messageIsLastInChain.append(chains)
                continue
            }
            if section.count >= 2 {
                for j in 0...section.count - 2 {
                    let m0: ClassroomMessage = section[j]
                    let m1: ClassroomMessage = section[j+1]
                    // Last in chain if next one is different from current
                    chains.append(!((m0.isSentByYou && m1.isSentByYou) || (!m0.isSentByYou && !m1.isSentByYou)))
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
        self.topConstraintForCollectionView.constant = TOP_GAP
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
            let containerMaxHeight = 0.2 * screenHeight
            if newHeight < containerMaxHeight {
                self.inputContainerHeightConstraint.constant = newHeight + 9.5 // Expand input container
                // Shift screen accordingly
                let diff = newHeight - self.textViewHeight
                
                if (self.isCollectionViewBlockingInput()) && self.textViewHeight < containerMaxHeight  {
                    // Need to shift only if collection view is blocking and text view is smaller than max height.
                    // If text view is greater than max height the container is not expanding anyway, so no point
                    // shifting collection view upwards.
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
            let message = ClassroomMessage(mid: "999", parentCid: "3", posterUid: "999", posterImageName: "https://scontent-sit4-1.xx.fbcdn.net/v/t31.0-8/14115448_10210401045933593_3308068963999044390_o.jpg?oh=270c123499c84c016e9328b62127bff5&oe=59245AAB", posterName: "Yihang", text: text.trim(), date: Date(), isSentByYou: true)
            self.messages.append(message)
            self.bucketMessagesIntoTime()
            self.assembleMessageIsLastInChain()
            self.resetInputContainer()
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.scrollToLastItemInCollectionView()
            self.removeTimeLabel()
        }
    }

    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(expandCell), name: NOTIF_EXPANDCLASSROOMCHATCELL, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openProfile), name: NOTIF_OPENPROFILE, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(launchRatingsController), name: NOTIF_LAUNCHRATING, object: nil)
    }
    
    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_EXPANDCLASSROOMCHATCELL, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_OPENPROFILE, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_LAUNCHRATING, object: nil)
    }
    
    func openProfile(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: String], let uid = userInfo["uid"] {
            log.info("opening profile of uid: \(uid)")
            let profilesToOpen = classroom.members.filter{$0.uid == uid}
            if profilesToOpen.count != 1 {
                return
            }
            let profileToOpen = profilesToOpen[0]
            let controller = ProfileController()
            controller.transitioningDelegate = self
            controller.interactor = interactor
            controller.profile = profileToOpen
            controller.modalTransitionStyle = .coverVertical
            controller.modalPresentationStyle = .overFullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    fileprivate func bottomOfCollectionView() -> CGFloat {
        let lastSection = self.timeBucketHeaders.count - 1
        if lastSection < 0 || lastSection >= self.messagesInTimeBuckets.count {
            return 0.0
        }
        let lastRow = self.messagesInTimeBuckets[lastSection].count - 1
        let indexPath = IndexPath(item: lastRow, section: lastSection)
        let attributes = self.collectionView.layoutAttributesForItem(at: indexPath)!
        let frame: CGRect = self.collectionView.convert(attributes.frame, to: self.view)
        return frame.maxY
    }
    
    fileprivate func topOfInput() -> CGFloat {
        return self.view.bounds.maxY - keyboardHeight - self.messageInputContainerView.bounds.height
    }
    
    fileprivate func isCollectionViewBlockingInput() -> Bool {
        return bottomOfCollectionView() >= topOfInput()
    }
    
    fileprivate func moveViewsAboveKeyboard(isKeyboardShowing: Bool, animationDuration: TimeInterval, distanceShifted: CGFloat, keyboardHeight: CGFloat) {
        if isKeyboardShowing {
            
            // Have to set this such that if the keyboard was kept when it was expanded the top constraint for collection view is set to the right value
            self.topConstraintForCollectionView.constant = self.TOP_GAP - (self.inputContainerHeightConstraint.constant - 45.0)
            UIView.animate(withDuration: animationDuration, animations: {
                if self.isCollectionViewBlockingInput() {
                    self.view.frame.origin.y = -distanceShifted
                    // Keyboard is shifted less because view already shifts by distance
                    self.bottomConstraintForInput.constant = -keyboardHeight + distanceShifted
                } else {
                    self.bottomConstraintForInput.constant = -keyboardHeight
                    self.view.layoutIfNeeded()
                }
            })
        } else {
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.frame.origin.y = 0
                self.bottomConstraintForInput.constant = 0
            })
        }
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            
            let isKeyboardShowing = notification.name != Notification.Name.UIKeyboardWillHide
            let keyboardViewEndFrame = view.convert(keyboardFrame, from: view.window)
            self.keyboardHeight = keyboardViewEndFrame.height
            
            let distanceShifted = min(keyboardViewEndFrame.height, abs(bottomOfCollectionView() - topOfInput() + SECTION_HEADER_HEIGHT))
            
            // NOTE: iOS 10 works fine with this
            if #available(iOS 10, *) {
                self.moveViewsAboveKeyboard(isKeyboardShowing: isKeyboardShowing, animationDuration: animationDuration, distanceShifted: distanceShifted, keyboardHeight: keyboardViewEndFrame.height)
            } else {
                UIView.animate(withDuration: 0, animations: {}, completion: { (completed) in
                    self.moveViewsAboveKeyboard(isKeyboardShowing: isKeyboardShowing, animationDuration: animationDuration, distanceShifted: distanceShifted, keyboardHeight: keyboardViewEndFrame.height)
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
        self.collectionView.scrollsToTop = false
        self.TOP_GAP = self.navigationController!.navigationBar.frame.height + 0.7*SECTION_HEADER_HEIGHT + 40.0
        
        let layout = UICollectionViewFlowLayout()
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: SECTION_HEADER_HEIGHT)
        self.collectionView.setCollectionViewLayout(layout, animated: false)
        self.automaticallyAdjustsScrollViewInsets = false
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0.8*SECTION_HEADER_HEIGHT, right: 0) // Fix top and bottom padding since automaticallyAdjustScrollViewInsets set to false
        
        self.collectionView.register(ClassroomChatCell.self, forCellWithReuseIdentifier: CELL_ID)
        self.collectionView.register(ChatHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CELL_HEADER_ID)
        
        self.view.insertSubview(collectionView, at: 0)
        
        self.view.addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        self.view.addConstraintsWithFormat("V:[v0]", views: collectionView)
        self.topConstraintForCollectionView = NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: self.TOP_GAP)
        self.view.addConstraint(self.topConstraintForCollectionView)
        
        self.setupEmptyPlaceholderView()
        
        // Panning on collection view keeps keyboard
        let panToKeepKeyboardRecognizer = UIPanGestureRecognizer(target: self, action: #selector(keepKeyboard))
        panToKeepKeyboardRecognizer.delegate = self
        self.collectionView.addGestureRecognizer(panToKeepKeyboardRecognizer)
        
        // Scroll collection view to the bottom to most recent message upon first entering screen
        // TODO: This will be moved away to Firebase
        UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.scrollToLastItemInCollectionView(animated: false)
        })
    }
    
    func keepKeyboard(gestureRecognizer: UIPanGestureRecognizer) {
        self.topConstraintForCollectionView.constant = TOP_GAP
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ClassroomChatCell
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
        let cellHeight = message.isSentByYou ? estimatedFrame.height + 11 : estimatedFrame.height + 11 + 19
        if let cell = self.collectionView.cellForItem(at: indexPath) as? ClassroomChatCell {
            if cell.shouldExpand {
                self.cellTimeLabel.removeFromSuperview()
                let cellFrame = self.collectionView.convert(cell.frame, to: self.view)
                var yi = cellFrame.origin.y + cellFrame.height
                // Insert timeLabel here
                yi += 12
                if tappedIndexPath == nil {
                    tappedIndexPath = indexPath
                }
                else {
                    if indexPath.section > tappedIndexPath!.section || (indexPath.section == tappedIndexPath!.section && indexPath.row > tappedIndexPath!.row) {
                        yi -= 21
                    } else if indexPath.section == tappedIndexPath!.section && indexPath.row == tappedIndexPath!.row {
                        // Clicked to hide
                        self.tappedIndexPath = nil
                        cell.shouldExpand = false
                        // Return with no expansion
                        return CGSize(width: view.frame.width, height: cellHeight)
                    }
                    tappedIndexPath = indexPath
                }
                
                let xi: CGFloat = message.isSentByYou ? 55.0 : 45.0
                let labelFrameInView = CGRect(x: xi, y: yi, width: self.view.frame.width - 80, height: 15)
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
                return CGSize(width: view.frame.width, height: cellHeight + 20.0)
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
        // Called by ClassroomChatCell's messageTextView to invalidate layout
        UIView.performWithoutAnimation {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    // Remove time label is called upon observing more messages (pull up) and reobserve (new messages coming in)
    fileprivate func removeTimeLabel() {
        self.cellTimeLabel.removeFromSuperview()
        // Find index path and set unchecked
        if tappedIndexPath != nil {
            if let cell = collectionView(self.collectionView, cellForItemAt: tappedIndexPath!) as? ChatCell {
                self.tappedIndexPath = nil
                cell.shouldExpand = false
            }
        }
    }
}
