//
//  SoundSmartAlertController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 3/2/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class SoundSmartAlertController: UIViewController {
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    fileprivate lazy var soundSmartIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "soundsmart")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate lazy var soundSmartLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        var str = NSMutableAttributedString(string: "Don't know what to say? Sound smart (or just silly) with this button below, which only appears in times of great need.", attributes: [NSForegroundColorAttributeName: GREEN_UICOLOR, NSParagraphStyleAttributeName: paragraphStyle])
        let str2 = NSMutableAttributedString(string: "\n\nWARNING: This will directly post a message under your name.", attributes: [NSForegroundColorAttributeName: RED_UICOLOR, NSParagraphStyleAttributeName: paragraphStyle])
        str.append(str2)
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
        
        containerView.addSubview(soundSmartIcon)
        containerView.addSubview(soundSmartLbl)
        
        containerView.addConstraintsWithFormat("V:|-12-[v0(50)]-6-[v1(150)]-12-|", views: soundSmartIcon, soundSmartLbl)
        containerView.addConstraintsWithFormat("H:[v0(50)]", views: soundSmartIcon)
        containerView.addConstraint(NSLayoutConstraint(item: soundSmartIcon, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: soundSmartLbl)
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
}
