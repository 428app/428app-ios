//
//  TutorialAlertController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 3/1/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class TutorialAlertController: UIViewController {
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    fileprivate lazy var tutorialInfoIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "infoicon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate lazy var tutorialLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let str = NSMutableAttributedString(string: "View tutorial by clicking the info icon on the top right.", attributes: [NSForegroundColorAttributeName: GREEN_UICOLOR, NSParagraphStyleAttributeName: paragraphStyle])
        label.attributedText = str
        label.numberOfLines = 0
        return label
    }()
    
    func dismissScreen() {
        notCheckedOutTutorial = false
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
        
        containerView.addSubview(tutorialInfoIcon)
        containerView.addSubview(tutorialLbl)
        
        containerView.addConstraintsWithFormat("V:|-12-[v0(50)][v1(60)]-8-|", views: tutorialInfoIcon, tutorialLbl)
        containerView.addConstraintsWithFormat("H:[v0(50)]", views: tutorialInfoIcon)
        containerView.addConstraint(NSLayoutConstraint(item: tutorialInfoIcon, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: tutorialLbl)
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
}
