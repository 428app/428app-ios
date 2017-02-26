//
//  ModalQuestionController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/20/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Social

class ModalQuestionController: UIViewController {
    
    let CORNER_RADIUS: CGFloat = 15.0
    let HORIZONTAL_MARGIN: CGFloat = 28.0
    let VERTICAL_MARGIN: CGFloat = UIScreen.main.bounds.height * 0.3
    
    var classroom: Classroom! {
        didSet {
            // Set modal info
            _ = downloadImage(imageUrlString: classroom.imageName, completed: { image in
                self.questionImageView.image = image
            })
            self.questionText.text = classroom.questionText
        }
    }
    
    // MARK: Question box
    
    fileprivate lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = GREEN_UICOLOR
        view.layer.cornerRadius = self.CORNER_RADIUS
        return view
    }()
    
    fileprivate lazy var questionImageView: UIImageView = {
        let frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width - self.HORIZONTAL_MARGIN * 2, height: 150)
       let imageView = UIImageView(frame: frame)
        imageView.contentMode = .scaleAspectFill
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: imageView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: self.CORNER_RADIUS - 2, height: self.CORNER_RADIUS - 2)).cgPath
        maskLayer.path = path
        imageView.layer.mask = maskLayer
        return imageView
    }()
    
    fileprivate let questionText: UITextView = {
       let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.backgroundColor = GREEN_UICOLOR
        textView.textColor = UIColor.white
        textView.textAlignment = .left
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = true
        textView.isEditable = false
        textView.isSelectable = false
        return textView
    }()
    
    // MARK: Share
    
    fileprivate lazy var fbButton: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.setBackgroundColor(color: FB_BLUE_UICOLOR, forState: .normal)
        btn.setBackgroundColor(color: UIColor(red: 50/255.0, green: 75/255.0, blue: 128/255.0, alpha: 1.0), forState: .highlighted) // Darker shade of blue
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitle("Share on Facebook", for: .normal)
        btn.addTarget(self, action: #selector(shareOnFb), for: .touchUpInside)
        btn.layer.cornerRadius = 5.0
        btn.clipsToBounds = true
        btn.isHidden = true
        return btn
    }()
    
    fileprivate lazy var tweetButton: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.setBackgroundColor(color: UIColor(red: 29/255.0, green: 202/255.0, blue: 255/255.0, alpha: 1.0), forState: .normal)
        btn.setBackgroundColor(color: UIColor(red: 0/255.0, green: 132/255.0, blue: 180/255.0, alpha: 1.0), forState: .highlighted) // Darker shade of blue
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitle("Post to Twitter", for: .normal)
        btn.addTarget(self, action: #selector(shareOnTwitter), for: .touchUpInside)
        btn.layer.cornerRadius = 5.0
        btn.clipsToBounds = true
        btn.isHidden = true
        return btn
    }()
    
    func shareOnFb() {
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                logAnalyticsEvent(key: kEventOpenShareQuestion, params: ["question": self.classroom.questionText as NSObject])
                if let url = URL(string: self.classroom.shareImageName) {
                    socialController.add(url)
                    self.present(socialController, animated: true, completion: {})
                    socialController.completionHandler = { (result:SLComposeViewControllerResult) in
                        if result == SLComposeViewControllerResult.done {
                            logAnalyticsEvent(key: kEventSuccessShareQuestion, params: ["question": self.classroom.questionText as NSObject])
                        }
                    }
                }
            }
        }
    }
    
    func shareOnTwitter() {
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter)) {
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeTwitter) {
                logAnalyticsEvent(key: kEventOpenTweetQuestion, params: ["question": self.classroom.questionText as NSObject])
                socialController.setInitialText(self.classroom.questionText)
                if let url = URL(string: self.classroom.shareImageName) {
                    socialController.add(url)
                }
                self.present(socialController, animated: true, completion: {})
                socialController.completionHandler = { (result:SLComposeViewControllerResult) in
                    if result == SLComposeViewControllerResult.done {
                        logAnalyticsEvent(key: kEventSuccessTweetQuestion, params: ["question": self.classroom.questionText as NSObject])
                    }
                }
            }
        }
    }
    
    func dismissScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
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
        questionText.flashScrollIndicators()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        fbButton.isHidden = false
        tweetButton.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
    }
    
    fileprivate func setupViews() {
        view.addSubview(containerView)
        view.addSubview(fbButton)
        view.addSubview(tweetButton)
        
        view.addConstraintsWithFormat("H:|-\(self.HORIZONTAL_MARGIN)-[v0]-\(self.HORIZONTAL_MARGIN)-|", views: containerView)
        view.addConstraintsWithFormat("V:|-\(self.VERTICAL_MARGIN * 0.7)-[v0]-\(self.VERTICAL_MARGIN * 1.2)-|", views: containerView)
        
        view.addConstraintsWithFormat("H:|-\(self.HORIZONTAL_MARGIN)-[v0]-\(self.HORIZONTAL_MARGIN)-|", views: fbButton)
        view.addConstraintsWithFormat("H:|-\(self.HORIZONTAL_MARGIN)-[v0]-\(self.HORIZONTAL_MARGIN)-|", views: tweetButton)
        view.addConstraint(NSLayoutConstraint(item: fbButton, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        view.addConstraintsWithFormat("V:[v0(40)]-[v1(40)]", views: fbButton, tweetButton)
        
        containerView.addSubview(questionImageView)
        containerView.addSubview(questionText)
        
        containerView.addConstraintsWithFormat("V:|[v0(150)]-3-[v1]-8-|", views: questionImageView, questionText)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: questionImageView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
    }
}
