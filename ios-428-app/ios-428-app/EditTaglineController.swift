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
    
    var tagline1: String? {
        didSet {
            self.tagline1TextView.text = tagline1
            self.tagline1CountLabel.text = "\(MAX_CHARACTERS - tagline1!.characters.count)"
        }
    }
    
    var tagline2: String? {
        didSet {
            self.tagline2TextView.text = tagline2
            self.tagline2CountLabel.text = "\(MAX_CHARACTERS - tagline2!.characters.count)"
        }
    }
    
    fileprivate lazy var saveButton: UIBarButtonItem = {
        let button: UIBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.saveEdits))
        button.isEnabled = false
        return button
    }()
    
    func saveEdits() {
        log.info("Save tagline edits to server")
        let tagline1Saved = tagline1TextView.text.trim()
        let tagline2Saved = tagline2TextView.text.trim()
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.rightBarButtonItem = saveButton
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(keepKeyboard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterObservers()
    }
    
    // MARK: Views
    
    fileprivate func placeholderTemplate() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.lightGray
        label.sizeToFit()
        label.isHidden = true
        return label
    }
    
    fileprivate lazy var tagline1Placeholder: UILabel = {
        let label: UILabel = self.placeholderTemplate()
        label.text = "the app we call 428..."
        return label
    }()
    
    fileprivate lazy var tagline2Placeholder: UILabel = {
        let label: UILabel = self.placeholderTemplate()
        label.text = "make my mark on the world..."
        return label
    }()
    
    fileprivate func textViewTemplate() -> UITextView {
        let textView = UITextView()
        textView.font = FONT_MEDIUM_MID
        textView.textColor = UIColor.black
        textView.backgroundColor = GRAY_UICOLOR
        textView.delegate = self
        textView.textAlignment = .left
        textView.tintColor = GREEN_UICOLOR
        return textView
    }
    
    fileprivate lazy var tagline1TextView: UITextView = {
        let textView: UITextView = self.textViewTemplate()
        return textView
    }()
    
    fileprivate lazy var tagline2TextView: UITextView = {
        let textView: UITextView = self.textViewTemplate()
        return textView
    }()
    
    fileprivate func labelTemplate() -> UILabel {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .left
        return label
    }
    
    fileprivate lazy var tagline1Label: UILabel = {
        let label: UILabel = self.labelTemplate()
        label.text = "I am working on..."
        return label
    }()
    
    fileprivate lazy var tagline2Label: UILabel = {
        let label: UILabel = self.labelTemplate()
        label.text = "I want to eventually..."
        return label
    }()
    
    fileprivate func countLabelTemplate() -> UILabel {
        let label = UILabel()
        label.font = FONT_HEAVY_SMALL
        label.textColor = UIColor.gray
        label.textAlignment = .right
        label.backgroundColor = GRAY_UICOLOR
        return label
    }
    
    fileprivate lazy var tagline1CountLabel: UILabel = {
        let label: UILabel = self.countLabelTemplate()
        return label
    }()
    
    fileprivate lazy var tagline2CountLabel: UILabel = {
        let label: UILabel = self.countLabelTemplate()
        return label
    }()
    
    fileprivate func setupViews() {
        view.addSubview(tagline1Label)
        view.addSubview(tagline1TextView)
        view.addSubview(tagline2Label)
        view.addSubview(tagline2TextView)
        view.addSubview(tagline1Placeholder)
        view.addSubview(tagline2Placeholder)
        view.addSubview(tagline1CountLabel)
        view.addSubview(tagline2CountLabel)
        
        view.addConstraintsWithFormat("H:|-8-[v0]", views: tagline1Label)
        view.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: tagline1TextView)
        view.addConstraintsWithFormat("H:|-8-[v0]", views: tagline2Label)
        view.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: tagline2TextView)
        view.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: tagline1CountLabel)
        view.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: tagline2CountLabel)
        
        view.addConstraint(NSLayoutConstraint(item: tagline1Label, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 12.0))
        
        // Each text view is 0.3 * screenSize
        let textviewHeight = 0.28 * UIScreen.main.bounds.height
        view.addConstraintsWithFormat("V:[v0(20)]-8-[v1(\(textviewHeight))][v2(20)]-20-[v3(20)]-8-[v4(\(textviewHeight))][v5(20)]", views: tagline1Label, tagline1TextView, tagline1CountLabel, tagline2Label, tagline2TextView, tagline2CountLabel)
        
        // Align placeholders to text views
        view.addConstraintsWithFormat("H:|-13-[v0]-13-|", views: tagline1Placeholder)
        view.addConstraintsWithFormat("H:|-13-[v0]-13-|", views: tagline2Placeholder)
        view.addConstraintsWithFormat("V:[v0(100)]", views: tagline1Placeholder)
        view.addConstraintsWithFormat("V:[v0(100)]", views: tagline2Placeholder)
        
        view.addConstraint(NSLayoutConstraint(item: tagline1Placeholder, attribute: .top, relatedBy: .equal, toItem: tagline1Label, attribute: .bottom, multiplier: 1.0, constant: -24.0))
        
        view.addConstraint(NSLayoutConstraint(item: tagline2Placeholder, attribute: .top, relatedBy: .equal, toItem: tagline2Label, attribute: .bottom, multiplier: 1.0, constant: -24.0))
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == tagline1TextView {
            self.tagline1Placeholder.isHidden = !textView.text.isEmpty
        } else {
            self.tagline2Placeholder.isHidden = !textView.text.isEmpty
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        
        if numberOfChars <= MAX_CHARACTERS {
            if textView == tagline1TextView {
                tagline1CountLabel.text = "\(max(MAX_CHARACTERS - numberOfChars, 0))"
            } else {
                tagline2CountLabel.text = "\(max(MAX_CHARACTERS - numberOfChars, 0))"
            }
        }
        
        if textView == tagline1TextView {
            saveButton.isEnabled = numberOfChars > 0 && newText != tagline1
        } else {
            saveButton.isEnabled = numberOfChars > 0 && newText != tagline2
        }
        return numberOfChars < MAX_CHARACTERS
    }
    
    // MARK: Keyboard
    
    func keepKeyboard() {
        self.view.endEditing(true)
    }
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func getActiveTextView() -> UITextView? {
        if self.tagline1TextView.isFirstResponder {
            return self.tagline1TextView
        }
        if self.tagline2TextView.isFirstResponder {
            return self.tagline2TextView
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
