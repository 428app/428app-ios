//
//  EditProfessionalController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/18/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class EditProfessionalController: UIViewController, UITextFieldDelegate {
    
    var organization: String? {
        didSet {
            self.orgTextField.text = organization
        }
    }
    
    var school: String? {
        didSet {
            self.schoolTextField.text = school
        }
    }
    
    var discipline: String? {
        didSet {
            self.disciplineTextField.text = discipline
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        self.automaticallyAdjustsScrollViewInsets = false
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
    
    fileprivate func titleLabelTemplate() -> UILabel {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }
    
    fileprivate lazy var orgTitleLabel: UILabel = {
        let label = self.titleLabelTemplate()
        label.text = "Organization"
        return label
    }()
    
    fileprivate lazy var schoolTitleLabel: UILabel = {
        let label = self.titleLabelTemplate()
        label.text = "School"
        return label
    }()
    
    fileprivate lazy var disciplineTitleLabel: UILabel = {
        let label = self.titleLabelTemplate()
        label.text = "Discipline"
        return label
    }()
    
    fileprivate func textfieldTemplate() -> UITextField {
        let textfield = UITextField()
        textfield.delegate = self
        textfield.font = FONT_MEDIUM_LARGE
        textfield.textColor = UIColor.darkGray
        textfield.borderStyle = .none
        textfield.backgroundColor = GRAY_UICOLOR
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textfield.frame.height))
        textfield.leftView = paddingView
        textfield.leftViewMode = .always
        textfield.tintColor = GREEN_UICOLOR
        let editImageView = UIImageView(image: #imageLiteral(resourceName: "edit"))
        editImageView.frame = CGRect(x: 0, y: 0, width: editImageView.image!.size.width + 20.0, height: editImageView.image!.size.height)
        editImageView.contentMode = .center
        textfield.rightView = editImageView
        textfield.rightViewMode = .unlessEditing
        textfield.returnKeyType = .done
        return textfield
    }
    
    fileprivate lazy var orgTextField: UITextField = {
        let textfield = self.textfieldTemplate()
        textfield.placeholder = "Your company, or school"
        return textfield
    }()
    
    fileprivate lazy var schoolTextField: UITextField = {
        let textfield = self.textfieldTemplate()
        textfield.placeholder = "Your current or past school"
        return textfield
    }()
    
    fileprivate lazy var disciplineTextField: UITextField = {
        let textfield = self.textfieldTemplate()
        textfield.placeholder = "Your discipline or industry"
        return textfield
    }()
    
    fileprivate func setupViews() {
        view.addSubview(orgTitleLabel)
        view.addSubview(orgTextField)
        view.addSubview(schoolTitleLabel)
        view.addSubview(schoolTextField)
        view.addSubview(disciplineTitleLabel)
        view.addSubview(disciplineTextField)
        
        view.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: orgTitleLabel)
        view.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: orgTextField)
        view.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: schoolTitleLabel)
        view.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: schoolTextField)
        view.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: disciplineTitleLabel)
        view.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: disciplineTextField)
        
        view.addConstraint(NSLayoutConstraint(item: orgTitleLabel, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 15.0))
        view.addConstraintsWithFormat("V:[v0(20)]-5-[v1(45)]-25-[v2(20)]-5-[v3(45)]-25-[v4(20)]-5-[v5(45)]", views: orgTitleLabel, orgTextField, schoolTitleLabel, schoolTextField, disciplineTitleLabel, disciplineTextField)
    }
    
    // Mark: Text field
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        // Max number of characters is 50
        let maxLength = 50
        let nsString = textField.text as NSString?
        let newString = nsString?.replacingCharacters(in: range, with: string)
        if let newLength = newString?.characters.count {
            return newLength <= maxLength
        }
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // MARK: Move keyboard up if blocking
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func getActiveTextfield() -> UITextField? {
        if self.orgTextField.isFirstResponder {
            return self.orgTextField
        }
        if self.schoolTextField.isFirstResponder {
            return schoolTextField
        }
        if self.disciplineTextField.isFirstResponder {
            return disciplineTextField
        }
        return nil
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            
            let isKeyboardShowing = notification.name != Notification.Name.UIKeyboardWillHide
            let keyboardViewEndFrame = view.convert(keyboardFrame, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height
            guard let activeTextField = getActiveTextfield() else {
                return
            }
            let bottomOfView = activeTextField.frame.maxY
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

