//
//  DiscussModalController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/20/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class DiscussModalController: UIViewController {
    
    var topic: Topic? {
        didSet {
            // Set modal info
            self.topicImageView.image = #imageLiteral(resourceName: "classroom-fertility") //UIImage(named: topic!.imageName)
            self.topicPromptLabel.text = "Question 1"//topic!.prompt
            self.descriptionTextView.text = "What happens when sperm travels at the speed of light?"//topic!.description
        }
    }
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    fileprivate let topicImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    fileprivate let topicPromptLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let descriptionTextView: UITextView = {
       let textView = UITextView()
        textView.font = FONT_MEDIUM_MID
        textView.textColor = UIColor.darkGray
        textView.textAlignment = .left
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = true
        textView.isEditable = false
        textView.isSelectable = false
        return textView
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        descriptionTextView.flashScrollIndicators()
    }
    
    fileprivate func setupViews() {
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-25-[v0]-25-|", views: containerView)
        view.addConstraintsWithFormat("V:|-160-[v0]-160-|", views: containerView)
        
        containerView.addSubview(topicImageView)
        containerView.addSubview(topicPromptLabel)
        containerView.addSubview(descriptionTextView)
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: topicImageView)
        
        // Calculate height of prompt dynamically
        let frame = UIScreen.main.bounds
        let widthOfPrompt: CGFloat = frame.width - 25 - 25 - 12 - 12
        var promptHeight: CGFloat = 48.0
        if let promptHeight_ = topicPromptLabel.text?.heightWithConstrainedWidth(width: widthOfPrompt, font: topicPromptLabel.font) {
            promptHeight = promptHeight_
        }
        
        containerView.addConstraintsWithFormat("V:|[v0(250)]-12-[v1(20)]-6-[v2]-|", views: topicImageView, topicPromptLabel, descriptionTextView)
        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: topicPromptLabel)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: descriptionTextView)
    }
}
