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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.setupViews()
    }
    
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
}

