//
//  EditTaglineController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/18/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit


class EditTaglineController: UIViewController, UITextViewDelegate {
    
    fileprivate let MAX_CHARACTERS = 400
    
    var tagline: String? {
        didSet {
            self.taglineTextView.text = tagline
            self.taglineCountLabel.text = "\(MAX_CHARACTERS - tagline!.characters.count)"
            self.taglinePlaceholder.isHidden = tagline != ""
        }
    }
    
    
    fileprivate lazy var saveButton: UIBarButtonItem = {
        let button: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.saveEdits))
        button.isEnabled = false
        return button
    }()
    
    func saveEdits() {
        let taglineSaved = taglineTextView.text.trim().lowercaseFirstLetter()
        if myProfile != nil {
            myProfile!.tagline = taglineSaved
            NotificationCenter.default.post(name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
        }
        
        DataService.ds.updateUserFields(tagline: taglineSaved) { (isSuccess) in
            if !isSuccess {
                log.error("[Error] Taglines failed to be updated")
            }
        }
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GRAY_UICOLOR
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(popController))
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(keepKeyboard))
        self.view.addGestureRecognizer(panGestureRecognizer)
        self.setupViews()
    }
    
    func popController() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.extendedLayoutIncludesOpaqueBars = true
        super.viewWillAppear(animated)
        self.loadProfileData()
        self.registerObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterObservers()
    }
    
    func loadProfileData() {
        guard let profile = myProfile else {
            return
        }
        self.tagline = profile.tagline
    }
    
    // MARK: Views
    
    fileprivate lazy var taglinePlaceholder: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.lightGray
        label.sizeToFit()
        label.isHidden = true
        label.text = "At 4:28pm, you can find me..."
        return label
    }()
    
    fileprivate lazy var taglineTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.textColor = UIColor.darkGray
        textView.backgroundColor = UIColor.white
        textView.delegate = self
        textView.textAlignment = .left
        textView.textContainerInset = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
        textView.tintColor = GREEN_UICOLOR
        return textView
    }()
    
    fileprivate lazy var taglineLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.black
        label.textAlignment = .left
        label.text = "What I do at 4:28pm:"
        return label
    }()
    
    fileprivate lazy var taglineCountLabel: UILabel = {
        let label = PaddingLabel()
        label.font = FONT_HEAVY_SMALL
        label.textColor = UIColor.gray
        label.textAlignment = .right
        label.backgroundColor = UIColor.white
        return label
    }()
    
    fileprivate func setupViews() {
        view.addSubview(taglineLabel)
        view.addSubview(taglineTextView)
        view.addSubview(taglinePlaceholder)
        view.addSubview(taglineCountLabel)
        
        view.addConstraintsWithFormat("H:|-12-[v0]", views: taglineLabel)
        view.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: taglineTextView)
        view.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: taglineCountLabel)
        
        view.addConstraint(NSLayoutConstraint(item: taglineLabel, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 12.0))
        
        let textviewHeight = 0.33 * UIScreen.main.bounds.height
        view.addConstraintsWithFormat("V:[v0(20)]-8-[v1(\(textviewHeight))][v2(20)]", views: taglineLabel, taglineTextView, taglineCountLabel)
        
        // Align placeholders to text views
        view.addConstraintsWithFormat("H:|-23-[v0]-13-|", views: taglinePlaceholder)
        view.addConstraintsWithFormat("V:[v0(100)]", views: taglinePlaceholder)
        
        view.addConstraint(NSLayoutConstraint(item: taglinePlaceholder, attribute: .top, relatedBy: .equal, toItem: taglineLabel, attribute: .bottom, multiplier: 1.0, constant: -28.0))
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == taglineTextView {
            self.taglinePlaceholder.isHidden = !textView.text.isEmpty
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        
        if numberOfChars <= MAX_CHARACTERS {
            taglineCountLabel.text = "\(max(MAX_CHARACTERS - numberOfChars, 0))"
        }
        if numberOfChars < MAX_CHARACTERS {
            saveButton.isEnabled = numberOfChars > 0 && newText != tagline && !newText.trim().isEmpty
        }
        return numberOfChars < MAX_CHARACTERS
    }
    
    // MARK: Keyboard
    
    func keepKeyboard() {
        self.view.endEditing(true)
    }
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadProfileData), name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func getActiveTextView() -> UITextView? {
        if self.taglineTextView.isFirstResponder {
            return self.taglineTextView
        }
        return nil
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            
            let isKeyboardShowing = notification.name != Notification.Name.UIKeyboardWillHide
            let keyboardViewEndFrame = view.convert(keyboardFrame, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height
            guard let activeTextView = getActiveTextView() else {
                return
            }
            let bottomOfView = activeTextView.frame.maxY
            let topOfKeyboard = self.view.bounds.maxY - keyboardHeight
            
            UIView.animate(withDuration: animationDuration, animations: {
                if isKeyboardShowing && bottomOfView >= topOfKeyboard {
                    let distanceShifted = min(keyboardHeight, abs(bottomOfView - topOfKeyboard))
                    self.view.frame.origin.y = -distanceShifted
                } else {
                    self.view.frame.origin.y = 0
                }
            })
        }
    }
}
