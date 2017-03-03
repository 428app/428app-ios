//
//  NewPlaygroupAlertController.swift
//  ios-428-app
//
//  Shown when user's hasNewPlaygroup is non-null
//  Created by Leonard Loo on 2/11/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class NewPlaygroupAlertController: UIViewController {
    
    open var discipline: String!
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    fileprivate lazy var disciplineIcon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        if self.discipline == "Sorry" {
            imageView.image = #imageLiteral(resourceName: "sorry")
        } else {
            imageView.image = UIImage(named: getDisciplineIcon(discipline: self.discipline))
        }
        imageView.tintColor = GREEN_UICOLOR
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate lazy var disciplineLbl: UILabel = {
        let label = UILabel()
        if self.discipline == "Sorry" {
            label.font = UIFont.systemFont(ofSize: 16.0)
            label.text = "We were not able to get you a playgroup because there were too few users in your area. We apologize. But this also presents you an opportunity - you could work with us as an ambassador to spread curiosity in your area."
        } else {
            label.font = FONT_HEAVY_LARGE
            label.text = self.discipline
        }
        label.textAlignment = .center
        label.textColor = GREEN_UICOLOR
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate lazy var newPlaygroupLbl: UILabel = {
       let label = UILabel()
        if self.discipline == "Sorry" {
            label.text = "Please shoot us an email @ 428app@gmail.com."
        } else {
            label.text = "You've got a new playgroup!"
        }
        label.font = FONT_MEDIUM_MID
        label.textAlignment = .center
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        return label
    }()
    
    func dismissScreen() {
        DataService.ds.removeUserHasNewPlaygroup()
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
        containerView.addSubview(newPlaygroupLbl)
        
        if self.discipline == "Sorry" {
            containerView.addConstraintsWithFormat("V:|-12-[v0(50)]-2-[v1(120)]-8-[v2(40)]-|", views: disciplineIcon, disciplineLbl, newPlaygroupLbl)
        } else {
            containerView.addConstraintsWithFormat("V:|-12-[v0(50)]-5-[v1(20)]-8-[v2(40)]-|", views: disciplineIcon, disciplineLbl, newPlaygroupLbl)
        }

        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: disciplineLbl)
        containerView.addConstraintsWithFormat("H:[v0(50)]", views: disciplineIcon)
        containerView.addConstraint(NSLayoutConstraint(item: disciplineIcon, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: newPlaygroupLbl)
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
}
