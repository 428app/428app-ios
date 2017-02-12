//
//  NewClassroomAlertController.swift
//  ios-428-app
//
//  Shown when user's hasNewClassroom is non-null
//  Created by Leonard Loo on 2/11/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class NewClassroomAlertController: UIViewController {
    
    open var discipline: String!
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    fileprivate lazy var disciplineIcon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        imageView.image = UIImage(named: getDisciplineIcon(discipline: self.discipline))
        imageView.tintColor = GREEN_UICOLOR
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate lazy var disciplineLbl: UILabel = {
        let label = UILabel()
        label.text = self.discipline
        label.font = FONT_HEAVY_LARGE
        label.textAlignment = .center
        label.textColor = GREEN_UICOLOR
        return label
    }()
    
    fileprivate let newClassroomLbl: UILabel = {
       let label = UILabel()
        label.text = "You've got a new classroom!"
        label.font = FONT_MEDIUM_MID
        label.textAlignment = .center
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        return label
    }()
    
    func dismissScreen() {
        DataService.ds.removeUserHasNewClassroom()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissScreen))
        view.addGestureRecognizer(tapGestureRecognizer)
        view.isUserInteractionEnabled = true
        self.setupViews()
    }
    
    fileprivate func setupViews() {
        
        containerView.addSubview(disciplineIcon)
        containerView.addSubview(disciplineLbl)
        containerView.addSubview(newClassroomLbl)
        
        containerView.addConstraintsWithFormat("V:|-12-[v0(50)]-2-[v1(20)]-8-[v2(40)]-|", views: disciplineIcon, disciplineLbl, newClassroomLbl)
        containerView.addConstraintsWithFormat("H:[v0(50)]", views: disciplineIcon)
        containerView.addConstraint(NSLayoutConstraint(item: disciplineIcon, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: disciplineLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: newClassroomLbl)
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
}
