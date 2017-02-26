//
//  VoteAnswerPromptAlertController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 2/26/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class VoteAnswerPromptAlertController: UIViewController {
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    fileprivate func voteBtnTemplate(title: String) -> UIButton {
        let btn = UIButton()
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitleColor(RED_UICOLOR, for: .normal)
        btn.setTitleColor(UIColor.white, for: .highlighted)
        btn.setBackgroundColor(color: UIColor.white, forState: .normal)
        btn.setBackgroundColor(color: RED_UICOLOR, forState: .highlighted)
        btn.layer.borderColor = RED_UICOLOR.cgColor
        btn.layer.borderWidth = 0.8
        btn.layer.cornerRadius = 4.0
        btn.clipsToBounds = true
        btn.isEnabled = false
        return btn
    }
    
    fileprivate lazy var likeBtn: UIButton = {
        return self.voteBtnTemplate(title: "Cool")
    }()
    
    fileprivate lazy var dislikeBtn: UIButton = {
        return self.voteBtnTemplate(title: "Boring")
    }()
    
    fileprivate lazy var explanationLbl: UILabel = {
        let label = UILabel()
        label.text = "Vote each question and answer as boring or cool. Help us serve you more cool questions!"
        label.font = FONT_HEAVY_MID
        label.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let str = NSMutableAttributedString(string: "Vote each question and answer as boring or cool. Help us serve you more cool questions!", attributes: [NSForegroundColorAttributeName: RED_UICOLOR, NSParagraphStyleAttributeName: paragraphStyle])
        label.attributedText = str
        label.isHidden = true
        return label
    }()
    
    func dismissScreen() {
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
            self.dislikeBtn.backgroundColor = RED_UICOLOR
            self.dislikeBtn.titleLabel?.textColor = UIColor.white
        }) { (isSuccess) in
            UIView.animate(withDuration: 0.35, animations: {
                self.likeBtn.backgroundColor = RED_UICOLOR
                self.likeBtn.titleLabel?.textColor = UIColor.white
            }, completion: { (isSuccess) in
                UIView.animate(withDuration: 0.3, animations: { 
                    self.explanationLbl.isHidden = false
                })
            })
        }
    }
    
    fileprivate func setupViews() {
        let voteContainer = UIView()
        voteContainer.addSubview(likeBtn)
        voteContainer.addSubview(dislikeBtn)
        voteContainer.addConstraintsWithFormat("H:|[v0]-8-[v1]|", views: dislikeBtn, likeBtn)
        voteContainer.addConstraint(NSLayoutConstraint(item: dislikeBtn, attribute: .width, relatedBy: .equal, toItem: likeBtn, attribute: .width, multiplier: 1.0, constant: 0.0))
        voteContainer.addConstraintsWithFormat("V:|[v0]|", views: dislikeBtn)
        voteContainer.addConstraintsWithFormat("V:|[v0]|", views: likeBtn)
        
        containerView.addSubview(voteContainer)
        containerView.addSubview(explanationLbl)
        
        containerView.addConstraintsWithFormat("V:|-16-[v0(40)]-8-[v1(70)]-16-|", views: voteContainer, explanationLbl)
        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: voteContainer)
        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: explanationLbl)
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
}
