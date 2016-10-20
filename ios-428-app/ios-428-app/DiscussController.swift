//
//  DiscussController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class DiscussController: UIViewController, UIGestureRecognizerDelegate {
    
    var topic: Topic! {
        didSet {
            if let dateString = topic.dateString {
                self.navigationItem.title = dateString
            }
        }
    }
    
    // MARK: Prompt
    
    fileprivate func animatePrompt() {
        UIView.animate(withDuration: 0.2, delay: 0.5, animations: {
            self.promptLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }) { (completed) in
                UIView.animate(withDuration: 0.1, animations: { 
                    self.promptLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    fileprivate lazy var promptLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.backgroundColor = GREEN_UICOLOR
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.white
        label.textAlignment = .left
        label.numberOfLines = 2
        label.layer.cornerRadius = 4.0
        label.layer.masksToBounds = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openDescription))
        tapGestureRecognizer.delegate = self
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGestureRecognizer)
        
        return label
    }()
    
    func openDescription() {
        log.info("open description modal")
    }
    
    // MARK: Open description modal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.extendedLayoutIncludesOpaqueBars = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        animatePrompt()
    }
    
    override func viewWillLayoutSubviews() {
        self.setupViews()
    }
    
    fileprivate func setupViews() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.lineBreakMode = .byTruncatingTail
        promptLabel.attributedText = NSMutableAttributedString(string: topic.prompt, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        
        view.addSubview(promptLabel)
        view.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: promptLabel)
        view.addConstraint(NSLayoutConstraint(item: promptLabel, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        view.addConstraintsWithFormat("V:[v0(60)]", views: promptLabel)
        
    }
    
    // MARK: Chat
    
    
}
