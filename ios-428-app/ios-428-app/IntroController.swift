//
//  IntroController.swift
//  ios-428-app
//
//  This class is fired once for a new user.
//  Created by Leonard Loo on 10/22/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class IntroController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate {
    
    override func viewDidLoad() {
        self.view.backgroundColor = GRAY_UICOLOR
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(keepKeyboard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        self.setupViews()
    }
    
    // MARK: Views
    
    fileprivate let confessProfessionLbl: UILabel = {
       let label = UILabel()
        label.text = "Confess your profession:"
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()
    
    fileprivate lazy var disciplineTextField: UITextField = {
        let textfield = UITextField()
        textfield.delegate = self
        textfield.font = FONT_MEDIUM_LARGE
        textfield.textColor = UIColor.darkGray
        textfield.borderStyle = .none
        textfield.backgroundColor = UIColor.white
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: textfield.frame.height))
        textfield.leftView = paddingView
        textfield.leftViewMode = .always
        textfield.tintColor = GREEN_UICOLOR
        let editImageView = UIImageView(image: #imageLiteral(resourceName: "edit"))
        editImageView.frame = CGRect(x: 0, y: 0, width: editImageView.image!.size.width + 20.0, height: editImageView.image!.size.height)
        editImageView.contentMode = .center
        textfield.rightView = editImageView
        textfield.rightViewMode = .unlessEditing
        textfield.returnKeyType = .done
        textfield.placeholder = "Your discipline or industry"
        textfield.inputView = self.pickerView
        return textfield
    }()
    
    fileprivate func editDisciplineIconInTextField(imageString: String) {
        if imageString.isEmpty {
            // Null choice, display empty text field
            disciplineTextField.text = ""
            return
        }
        let image = UIImage(named: imageString)?.resizeWith(width: 20.0)
        let imageView: UIImageView = UIImageView(image: image)
        let width = image == nil ? 20 : image!.size.width + 20
        let height = image == nil ? 20 : image!.size.height
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        imageView.contentMode = .center
        disciplineTextField.leftView = imageView
        disciplineTextField.leftViewMode = .always
    }
    
    fileprivate lazy var goButton: UIButton = {
        let button = UIButton()
        button.setTitle("Change my life", for: .normal)
        button.titleLabel?.font = FONT_HEAVY_XLARGE
        button.setTitleColor(UIColor.white, for: .normal)
        button.setBackgroundColor(color: GREEN_UICOLOR, forState: .normal)
        button.setBackgroundColor(color: GREEN_UICOLOR.withAlphaComponent(0.6), forState: .highlighted)
        button.layer.cornerRadius = 4.0
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(goIntoApp), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    fileprivate func setupViews() {
        let containerView = UIView()
        containerView.addSubview(confessProfessionLbl)
        containerView.addSubview(disciplineTextField)
        containerView.addSubview(goButton)
        
        self.view.addSubview(containerView)
        self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        self.view.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: containerView)
        
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: confessProfessionLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: disciplineTextField)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: goButton)
        containerView.addConstraintsWithFormat("V:|-8-[v0(40)]-2-[v1(45)]-10-[v2(55)]-|", views: confessProfessionLbl, disciplineTextField, goButton)
    }
    
    // MARK: Picker view
    
    fileprivate lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.tintColor = GREEN_UICOLOR
        picker.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(keepPickerView))
        tap.delegate = self
        picker.addGestureRecognizer(tap)
        return picker
    }()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func keepPickerView() {
        self.view.endEditing(true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DISCIPLINE_OPTIONS.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return DISCIPLINE_OPTIONS[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        disciplineTextField.text = DISCIPLINE_OPTIONS[row]
        goButton.isHidden = self.disciplineTextField.text == nil || self.disciplineTextField.text!.trim() == ""
        if self.disciplineTextField.text == nil || self.disciplineTextField.text!.trim() == "" {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: disciplineTextField.frame.height))
            disciplineTextField.leftView = paddingView
        }
        editDisciplineIconInTextField(imageString: DISCIPLINE_ICONS[row])
    }
    
    // Enter main app after updating user profile data
    func goIntoApp() {
        keepKeyboard()
        // Set environment variable, then dismiss to Login
        DataService.ds.updateUserFields(discipline: disciplineTextField.text, completed: { (isSuccess) in
            if !isSuccess {
                showErrorAlert(vc: self, title: "Unable to proceed", message: "We apologize. We seem to be unable to log you in at this time. Please try again later.")
            } else {
                log.info("Going into the app")
                justFinishedIntro = true
                setHasToFillInfo(hasToFill: false)
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    // MARK: Text field

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    func keepKeyboard() {
        self.view.endEditing(true)
    }
    
}
