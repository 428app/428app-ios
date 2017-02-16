//
//  ChatClassroomController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ChatClassroomController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /** FIREBASE **/
    fileprivate var chatQueryAndHandle: (FIRDatabaseQuery, FIRDatabaseHandle)!
    fileprivate var classroomRefAndHandle: (FIRDatabaseReference, FIRDatabaseHandle)!
    
    fileprivate var numMessages: UInt = 30 // Increases as user scrolls to top of collection view
    fileprivate let NUM_INCREMENT: UInt = 10 // Downloads 10 messages per scroll
    
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
    
    var classroom: Classroom!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupFirebase()
        self.view.backgroundColor = UIColor.white
        self.setupNavigationBar()
        self.setupPromptView()
        self.setupCollectionView()
        self.setupInputComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.animateQuestionBanner()
        DataService.ds.seeClassroomMessages(classroom: self.classroom) { (isSuccess) in }
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.navigationBar.barTintColor = RED_UICOLOR
        self.registerObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DataService.ds.seeClassroomMessages(classroom: self.classroom) { (isSuccess) in }
        self.tabBarController?.tabBar.isHidden = false
        self.unregisterObservers()
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil { // Leaving
            self.removeFirebaseObservers()
        }
    }
    
    fileprivate func removeFirebaseObservers() {
        if self.chatQueryAndHandle != nil {
            self.chatQueryAndHandle.0.removeObserver(withHandle: self.chatQueryAndHandle.1)
        }
        if self.classroomRefAndHandle != nil {
            self.classroomRefAndHandle.0.removeObserver(withHandle: self.classroomRefAndHandle.1)
        }
    }
    
    // MARK: Firebase
    
    fileprivate func initClassroomObserver() {
        self.activityIndicator.startAnimating()
        // Small hack to make it not show up when the load time is less than 2 seconds
        self.activityIndicator.isHidden = true
        UIView.animate(withDuration: 2.0, animations: {}, completion: { (isSuccess) in
            if self.activityIndicator.isAnimating {
                self.activityIndicator.isHidden = false
            }
        })
        
        // Classroom could have already been initialized, so just init messages straight away
        let classroomHasBeenInit: Bool = self.classroom.members.count > 0
        if classroomHasBeenInit {
            self.initMessages()
        }
        
        self.classroomRefAndHandle = DataService.ds.observeSingleClassroom(classroom: self.classroom, completed: { (isSuccess, updatedClassroom) in
            
            // Update fields individually instead of replacing, as we don't want to replace messages
            self.classroom.members = updatedClassroom.members
            self.classroom.questions = updatedClassroom.questions
            self.classroom.superlativeType = updatedClassroom.superlativeType
            self.classroom.hasSuperlatives = updatedClassroom.hasSuperlatives
            self.classroom.didYouKnowId = updatedClassroom.didYouKnowId
            
            // Show superlative alert when there are superlatives and user has not voted
            if self.classroom.hasSuperlatives && self.classroom.superlativeType == SuperlativeType.NOTVOTED {
                self.showSuperlativeAlert()
            }
            if self.messages.isEmpty && !classroomHasBeenInit {
                self.initMessages()
            }
        })
    }
    
    func loadMoreMessages() {
        self.numMessages += NUM_INCREMENT
        self.observeMore()
    }
    
    /**
     Here's why we need 3 functions for observing chat from Firebase:
     By default reobserveMessages() which loads on every new message being added will scroll the chat to the bottom
     of the screen. However, we don't want that on the two occasions when we first enter the screen and we pull to refresh. Hence,
     1) initMessages is used to hide the messages first so I can scroll to the bottom before displaying them. This is a hack I invented to make a more natural transition from Private Chats to this page.
     2) observeMore is used to change the limit of the query (pull to refresh), and at the same time NOT scroll to the bottom. By default, observeMore will scroll the table to the top.
     NOTE the following intended behavior:
     - When a user receives/sends a message, the scroll view is scrolled to the bottom
     - When a user opens the keyboard the scroll view remains at the same position
     - When a user scrolls up to load more messages and leaves this chat screen, the next time the user is back the more messages will be gone
     **/
    
    // Called after entering the page
    fileprivate func initMessages() {
        if self.chatQueryAndHandle != nil {
            return
        }
        
        DataService.ds.observeClassChatMessagesOnce(limit: self.numMessages, classroom: self.classroom) { (isSuccess, updatedClassroom) in
            self.activityIndicator.stopAnimating()
            if (!isSuccess || updatedClassroom == nil) {
                // No messages yet, display placeholder view in the middle
                self.emptyPlaceholderView.isHidden = false
                self.emptyPlaceholderView.isUserInteractionEnabled = true
                log.info("No messages updated for private chat")
                self.reobserveMessages()
                return
            }
            
            // There are messages, hide and disable empty placeholder view
            self.emptyPlaceholderView.isHidden = true
            self.emptyPlaceholderView.isUserInteractionEnabled = false
            
            // Update private chat and messages
            self.classroom = updatedClassroom
            self.messages = self.classroom.classroomMessages
            
            self.organizeMessages()
            
            
            // Simple hack to load the bottom of the collection view without visually showing it
            UIView.animate(withDuration: 0, animations: {
                // Collection view is hidden first so the scrolling is not visible to the user
                self.collectionView.isHidden = true
                self.collectionView.reloadData()
            }, completion: { (isSuccess) in
                self.scrollToLastItemInCollectionView(animated: false)
                self.collectionView.isHidden = false
                self.reobserveMessages()
            })
        }
    }
    
    // Called upon pull to refresh
    fileprivate func observeMore() {

        self.removeTimeLabel()
        
        if self.chatQueryAndHandle != nil {
            self.chatQueryAndHandle.0.removeObserver(withHandle: self.chatQueryAndHandle.1)
        }
        self.refreshControl.beginRefreshing()
        self.pullToRefreshIndicator.startAnimating()
        
        DataService.ds.observeClassChatMessagesOnce(limit: self.numMessages, classroom: self.classroom) { (isSuccess, updatedClassroom) in
            self.refreshControl.endRefreshing()
            self.pullToRefreshIndicator.stopAnimating()
            
            if (!isSuccess || updatedClassroom == nil) {
                // No messages yet, display placeholder view in the middle to prompt user to interact with new private chat
                self.emptyPlaceholderView.isHidden = false
                self.emptyPlaceholderView.isUserInteractionEnabled = true
                log.info("No messages updated for classroom")
                self.reobserveMessages()
                return
            }
            log.info("More classroom messages pulled")
            
            // There are messages, hide and disable empty placeholder view
            self.emptyPlaceholderView.isHidden = true
            self.emptyPlaceholderView.isUserInteractionEnabled = false
            
            // Update private chat and messages
            self.classroom = updatedClassroom
            
            // Logic to scroll to the right chat message upon loading more messages above
            if self.messagesInTimeBuckets.count > 0 && self.messagesInTimeBuckets[0].count > 0 {
                // Find the first message in the old message so we scroll to this one
                let firstMsg = self.messagesInTimeBuckets[0][0]
                self.messages = updatedClassroom!.classroomMessages
                self.organizeMessages()
                // Find this first message in the new messages to find the new row and section to scroll to
                var messageFound = false
                for section in 0..<self.messagesInTimeBuckets.count {
                    for row in 0..<self.messagesInTimeBuckets[section].count {
                        if self.messagesInTimeBuckets[section][row].mid == firstMsg.mid {
                            
                            // Set content offset to 1 before this spot
                            var before_section = 0
                            var before_row = 0
                            if row == 0 && section > 0 {
                                before_section = section - 1
                                before_row = self.messagesInTimeBuckets[before_section].count - 1
                            } else if row > 0 {
                                before_row = row - 1
                                before_section = section
                            } else {
                                break
                            }
                            
                            let indexPath = IndexPath(item: before_row, section: before_section)
                            self.collectionView.reloadData()
                            
                            let offset: CGFloat = self.collectionView.layoutAttributesForItem(at: indexPath)!.frame.origin.y
                            self.collectionView.setContentOffset(CGPoint(x: 0.0, y: offset), animated: false)
                            messageFound = true
                            break
                        }
                    }
                }
                // If not found, which is possibly a bug, just reload anyway
                if !messageFound {
                    self.collectionView.reloadData()
                }
            }
            
            else {
                // Previous messages are empty - this should very rarely happen, possibly only due to network connectivity issues
                self.messages = updatedClassroom!.classroomMessages
                self.organizeMessages()
                self.collectionView.reloadData()
            }
            
            // As the above is a single observe event, we need to restart the constant observer with a different numMessages set
            self.reobserveMessages()
        }
    }
    
    fileprivate func reobserveMessages() {
        if self.chatQueryAndHandle != nil {
            chatQueryAndHandle.0.removeObserver(withHandle: chatQueryAndHandle.1)
        }
        
        chatQueryAndHandle = DataService.ds.reobserveClassChatMessages(limit: self.numMessages, classroom: self.classroom, completed: { (isSuccess, updatedClassroom) in
            
            if (!isSuccess || updatedClassroom == nil) {
                // Rewind increment of numMessages
                if self.numMessages > self.NUM_INCREMENT {
                    self.numMessages -= self.NUM_INCREMENT
                }
                
                // No messages yet, display placeholder view in the middle to prompt user to interact with new private chat
                self.emptyPlaceholderView.isHidden = false
                self.emptyPlaceholderView.isUserInteractionEnabled = true
                log.info("No messages updated for classroom")
                return
            }
            
            // There are messages, hide and disable empty placeholder view
            self.emptyPlaceholderView.isHidden = true
            self.emptyPlaceholderView.isUserInteractionEnabled = false
            
            // Check if messages are exactly the same, if yes, then no need to update
            if self.messages.count == updatedClassroom!.classroomMessages.count {
                var areTheSame = true
                let updatedMessages = updatedClassroom!.classroomMessages.sorted(by: { (m1, m2) -> Bool in
                    return m1.date.compare(m2.date) == .orderedAscending
                })
                let oldMessages = self.messages.sorted(by: { (m1, m2) -> Bool in
                    return m1.date.compare(m2.date) == .orderedAscending
                })
                for i in 0..<updatedMessages.count {
                    if updatedMessages[i].mid != oldMessages[i].mid {
                        areTheSame = false
                        break
                    }
                }
                if areTheSame {
                    return
                }
            }
            
            // Update messages
            self.classroom = updatedClassroom
            self.messages = self.classroom.classroomMessages
            self.organizeMessages()
            self.collectionView.reloadData()
            self.scrollToLastItemInCollectionView(animated: false)
            self.removeTimeLabel()
        })
    }
    
    fileprivate lazy var pullToRefreshIndicator: CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading")!
        let activityIndicatorView = CustomActivityIndicatorView(image: image)
        return activityIndicatorView
    }()
    
    fileprivate lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = UIColor.clear
        control.backgroundColor = UIColor.clear
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()
    
    fileprivate lazy var activityIndicator: CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading-large")!
        let activityIndicatorView = CustomActivityIndicatorView(image: image)
        return activityIndicatorView
    }()
    
    fileprivate func setupFirebase() {
        
        // Setup empty placeholder view
        self.setupEmptyPlaceholderView()
        
        // Setup activity indicator for initial load
        self.collectionView.addSubview(activityIndicator)
        self.activityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.08 * self.view.frame.height)
        
        // Setup refresh control for pull-to-refresh
        self.refreshControl.addSubview(self.pullToRefreshIndicator)
        self.pullToRefreshIndicator.center = CGPoint(x: self.view.center.x, y: self.refreshControl.center.y)
        collectionView.addSubview(self.refreshControl)
        
//        self.initMessages()
        self.initClassroomObserver()
    }
    
    // MARK: Navigation
    
    fileprivate func setupNavigationBar() {
        self.navigationItem.title = self.classroom.title
        let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpace.width = -6.0
        let moreButton = UIBarButtonItem(image: #imageLiteral(resourceName: "more"), style: .plain, target: self, action: #selector(handleNavMore))
        self.navigationItem.rightBarButtonItems = [negativeSpace, moreButton]
    }
    
    func handleNavMore() {
        // Bring up alert controller to view classmates, answers or superlatives
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
        let superlativesAction = UIAlertAction(title: "Superlatives", style: .default) { (action) in
            self.launchSuperlativeController()
        }
        
        answersAction.isEnabled = self.classroom.questions.count > 1 // Only enable seeing answers if there is more than 1 answer (current answer)
        superlativesAction.isEnabled = classroom.hasSuperlatives
        alertController.addAction(classmatesAction)
        alertController.addAction(answersAction)
        alertController.addAction(superlativesAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: {
            alertController.view.tintColor = GREEN_UICOLOR
        })
    }
    
    // MARK: Question banner on top
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    fileprivate lazy var questionBanner: UILabel = {
        let label = UILabel()
        label.backgroundColor = GREEN_UICOLOR
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 1
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openDescription))
        tapGestureRecognizer.delegate = self
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGestureRecognizer)
        label.text = "Read Question \(self.classroom.questionNum) here"
        return label
    }()
    
    fileprivate let questionBannerBg: UIView = {
        let view = UIView()
        view.backgroundColor = GRAY_UICOLOR
        return view
    }()
    
    fileprivate func animateQuestionBanner() {
        UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
            self.questionBanner.transform = CGAffineTransform(translationX: 0.0, y: 50.0)
        })
    }
    
    func openDescription() {
        let modalController = ModalQuestionController()
        modalController.classroom = self.classroom
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .flipHorizontal
        self.present(modalController, animated: true, completion: nil)
    }
    
    fileprivate func setupPromptView() {
        view.addSubview(questionBannerBg)
        view.addSubview(questionBanner)
        view.addConstraintsWithFormat("H:|[v0]|", views: questionBannerBg)
        view.addConstraintsWithFormat("H:|[v0]|", views: questionBanner)
        view.addConstraint(NSLayoutConstraint(item: questionBannerBg, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: questionBanner, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -50.0))
        view.addConstraintsWithFormat("V:[v0(50)]", views: questionBannerBg)
       view.addConstraintsWithFormat("V:[v0(50)]", views: questionBanner)
    }
    
    // MARK: Superlatives
    
    fileprivate func showSuperlativeAlert() {
        let alertController = SuperlativeAlertController()
        alertController.classroom = self.classroom
        alertController.modalPresentationStyle = .overFullScreen
        alertController.modalTransitionStyle = .crossDissolve
        self.present(alertController, animated: true, completion: {
            alertController.view.tintColor = GREEN_UICOLOR
        })
    }
    
    func launchSuperlativeController() {
        let controller = SuperlativeController()
        controller.classroom = self.classroom
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
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
            self.resetInputContainer()
            DataService.ds.addClassChatMessage(classroom: self.classroom, text: text.trim(), completed: { (isSuccess, updatedClassroom) in
                if !isSuccess || updatedClassroom == nil {
                    
                    log.error("[Error] Message failed to be posted")
                    showErrorAlert(vc: self, title: "Error", message: "Could not send message. Please try again.")
                    return
                }
            })
        }
    }

    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(expandCell), name: NOTIF_EXPANDCLASSROOMCHATCELL, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openProfile), name: NOTIF_OPENPROFILE, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(launchSuperlativeController), name: NOTIF_LAUNCHVOTING, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sendMessageFromProfile), name: NOTIF_SENDMESSAGE, object: nil)
    }
    
    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_EXPANDCLASSROOMCHATCELL, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_OPENPROFILE, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_LAUNCHVOTING, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_SENDMESSAGE, object: nil)
    }
    
    func sendMessageFromProfile(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: Inbox], let inbox = userInfo["inbox"] {
            // Switch to Inbox tab, and let the rest of the transition happen in InboxController, based on the side effect inboxToOpen
            inboxToOpen = inbox // This must come before setting the tab selected index, or everything will screw up
            self.tabBarController?.selectedIndex = 2
        }
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
        self.TOP_GAP = self.navigationController!.navigationBar.frame.height + 0.7*SECTION_HEADER_HEIGHT + 50.0
        
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
        
        // Get poster image name and poster name
        let posterUid = message.posterUid
        let potentialPoster = classroom.members.filter({$0.uid == posterUid})
        if potentialPoster.count != 1 { // NOTE: This case will happen on first opening chat because profiles are not loaded yet
            return cell
        }
        let poster = potentialPoster[0]
        cell.configureCell(messageObj: message, posterImageName: poster.profileImageName, posterName: poster.name, viewWidth: view.frame.width, isLastInChain: isLastInChain)
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
        return UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
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
            if let cell = collectionView(self.collectionView, cellForItemAt: tappedIndexPath!) as? ClassroomChatCell {
                self.tappedIndexPath = nil
                cell.shouldExpand = false
            }
        }
    }
}
