//
//  ChatController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ChatController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate var messages: [Message]?
    fileprivate let cellId = "chatCell"

    var friend: Friend? {
        didSet { // Set from didSelect in ConnectionsController
            self.navigationItem.title = self.friend?.name
            self.messages = friend?.messages?.allObjects as? [Message]
            self.messages = self.messages?.sorted{($0.date!.timeIntervalSince1970) < ($1.date!.timeIntervalSince1970)}
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.showsVerticalScrollIndicator = false
        self.setupInputComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterObservers()
    }
    
    // MARK: Input
    
    fileprivate var bottomConstraintForInput: NSLayoutConstraint!
    
    fileprivate let messageInputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    fileprivate let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Type a message..."
        textField.textColor = UIColor.black
        textField.font = FONT_MEDIUM_MID
        return textField
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.setTitleColor(GREEN_UICOLOR, for: .normal)
        button.titleLabel?.font = FONT_HEAVY_MID
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    fileprivate func setupInputComponents() {
        view.addSubview(messageInputContainerView)
        view.addConstraintsWithFormat("H:|[v0]|", views: messageInputContainerView)
        view.addConstraintsWithFormat("V:[v0(48)]", views: messageInputContainerView)
        
        bottomConstraintForInput = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraintForInput)
        
        let topBorderView = UIView()
        topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        messageInputContainerView.addSubview(inputTextField)
        messageInputContainerView.addSubview(sendButton)
        messageInputContainerView.addSubview(topBorderView)
        messageInputContainerView.addConstraintsWithFormat("H:|-8-[v0][v1(60)]-8-|", views: inputTextField, sendButton)
        messageInputContainerView.addConstraintsWithFormat("V:|[v0]|", views: inputTextField)
        messageInputContainerView.addConstraintsWithFormat("V:|[v0]|", views: sendButton)
        messageInputContainerView.addConstraintsWithFormat("H:|[v0]|", views: topBorderView)
        messageInputContainerView.addConstraintsWithFormat("V:|[v0(0.5)]", views: topBorderView)
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let isKeyboardShowing = notification.name == Notification.Name.UIKeyboardWillShow
            self.bottomConstraintForInput.constant = isKeyboardShowing ? -keyboardFrame.height : 0
            
            UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                }, completion: { (completed) in
                    if self.messages != nil {
                        let indexPath = IndexPath(item: self.messages!.count - 1, section: 0)
                        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }
            })
        }
    }
    
    func handleSend() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = delegate.persistentContainer.viewContext
        if let friend = friend, let text = inputTextField.text {
            let message = ConnectionsController.createMessageForFriend(friend, text: text, minutesAgo: 0, context: context, isSender: true)
            do {
                try context.save()
                messages?.append(message)
                let insertionIndexPath = IndexPath(item: messages!.count - 1, section: 0)
                collectionView?.insertItems(at: [insertionIndexPath])
                collectionView?.scrollToItem(at: insertionIndexPath, at: .bottom, animated: true)
                inputTextField.text = nil
            } catch let err {
                print(err)
            }
        }
    }
    
    // MARK: Keyboard
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // MARK: Collection view
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = messages?.count {
            return count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatCell
        cell.messageTextView.isScrollEnabled = true
        cell.messageTextView.text = messages?[indexPath.item].text
        if let message = messages?[indexPath.item], let messageText = message .text, let profileImageName = message.friend?.profileImageName {
            cell.profileImageView.image = UIImage(named: profileImageName)
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: FONT_MEDIUM_MID], context: nil)
            if !message.isSender {
                cell.messageTextView.frame = CGRect(x: 45 + 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
                cell.textBubbleView.frame = CGRect(x: 45 - 8, y: -4, width: estimatedFrame.width + 16 + 8 + 8, height: estimatedFrame.height + 16 + 6)
                cell.profileImageView.isHidden = false
                cell.bubbleImageView.image = ChatCell.grayBubbleImage
                cell.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
                cell.messageTextView.textColor = UIColor.black
            } else {
                cell.messageTextView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 16 - 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
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
        if let messageText = messages?[indexPath.item].text {
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: FONT_MEDIUM_MID], context: nil)
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 16)
        }
        return CGSize(width: view.frame.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.inputTextField.endEditing(true)
    }
}
