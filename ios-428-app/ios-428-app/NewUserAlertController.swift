//
//  NewUserAlertController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 2/17/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class NewUserAlertController: UIViewController {
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    fileprivate lazy var underConstructionIcon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0))
        imageView.image = #imageLiteral(resourceName: "newuser")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate lazy var onTheWayLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let str = NSMutableAttributedString(string: "Your group is on the way. \nWhy not edit your profile first?", attributes: [NSForegroundColorAttributeName: GREEN_UICOLOR, NSParagraphStyleAttributeName: paragraphStyle])
        label.attributedText = str
        label.numberOfLines = 0
        return label
    }()
    
    func dismissScreen() {
        isFirstTimeUser = false
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
        
        containerView.addSubview(underConstructionIcon)
        containerView.addSubview(onTheWayLbl)
        
        containerView.addConstraintsWithFormat("V:|-12-[v0(70)][v1(60)]-8-|", views: underConstructionIcon, onTheWayLbl)
        containerView.addConstraintsWithFormat("H:[v0(80)]", views: underConstructionIcon)
        containerView.addConstraint(NSLayoutConstraint(item: underConstructionIcon, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: onTheWayLbl)
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
}
