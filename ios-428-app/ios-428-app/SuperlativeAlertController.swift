//
//  SuperlativeAlertController.swift
//  ios-428-app
//
//  Launched from ChatClassroomController when user superlatives are available but user has not voted.
//
//  Created by Leonard Loo on 1/3/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class SuperlativeAlertController: UIViewController {
    
    open var classroom: Classroom!
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    fileprivate let superlativeIcon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        imageView.image = #imageLiteral(resourceName: "rateclassmates")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let superlativeLbl: UILabel = {
        let label = UILabel()
        label.text = "It's time to vote for superlatives!"
        label.font = FONT_MEDIUM_LARGE
        label.textAlignment = .center
        label.minimumScaleFactor = 0.6
        label.numberOfLines = 1
        return label
    }()
    
    fileprivate func btnTemplate() -> UIButton {
        let btn = UIButton()
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitleColor(GREEN_UICOLOR, for: .normal)
        btn.setTitleColor(UIColor.white, for: .highlighted)
        btn.setBackgroundColor(color: UIColor.white, forState: .normal)
        btn.setBackgroundColor(color: GREEN_UICOLOR, forState: .highlighted)
        btn.layer.cornerRadius = 4.0
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = GREEN_UICOLOR.cgColor
        btn.tintColor = UIColor.white
        return btn
    }
    
    fileprivate lazy var voteBtn: UIButton = {
        let btn = self.btnTemplate()
        btn.setTitle("Vote now", for: .normal)
        btn.addTarget(self, action: #selector(self.voteNow), for: .touchUpInside)
        return btn
    }()
    
    fileprivate lazy var cancelBtn: UIButton = {
        let btn = self.btnTemplate()
        btn.setTitle("Cancel", for: .normal)
        btn.addTarget(self, action: #selector(self.dismissScreen), for: .touchUpInside)
        return btn
    }()
    
    func dismissScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func voteNow() {
        self.dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: NOTIF_LAUNCHVOTING, object: nil)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        self.setupViews()
    }

    fileprivate func setupViews() {
        
        containerView.addSubview(superlativeIcon)
        containerView.addSubview(superlativeLbl)
        containerView.addSubview(voteBtn)
        containerView.addSubview(cancelBtn)
        containerView.addConstraintsWithFormat("V:|-8-[v0(50)]-8-[v1(30)]-8-[v2(50)]-8-[v3(50)]-8-|", views: superlativeIcon, superlativeLbl, voteBtn, cancelBtn)
        containerView.addConstraintsWithFormat("H:[v0(50)]", views: superlativeIcon)
        containerView.addConstraint(NSLayoutConstraint(item: superlativeIcon, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: superlativeLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: voteBtn)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: cancelBtn)
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
}

