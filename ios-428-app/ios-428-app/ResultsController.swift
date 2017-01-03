//
//  ResultsController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 1/3/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit
import FBSDKShareKit
import Social

class ResultsController: UIViewController {
    
    fileprivate let didYouKnowLbl: UILabel = {
       let lbl = UILabel()
        lbl.font = FONT_HEAVY_LARGE
        lbl.textColor = GREEN_UICOLOR
        lbl.textAlignment = .center
        lbl.text = "Did you know?"
        return lbl
    }()
    
    fileprivate let didYouKnowText: UITextView = {
       let textView = UITextView()
        textView.showsHorizontalScrollIndicator = false
        textView.font = FONT_MEDIUM_MID
        textView.textColor = UIColor.black
        textView.isEditable = false
        textView.isSelectable = true
        textView.tintColor = RED_UICOLOR
        textView.dataDetectorTypes = .all
        return textView
    }()
    
    fileprivate lazy var fbButton: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.setBackgroundColor(color: FB_BLUE_UICOLOR, forState: .normal)
        btn.setBackgroundColor(color: FB_BLUE_UICOLOR, forState: .highlighted)
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitle("Share on Facebook", for: .normal)
        btn.addTarget(self, action: #selector(shareOnFb), for: .touchUpInside)
        btn.layer.cornerRadius = 5.0
        btn.clipsToBounds = true
        return btn
    }()
    
    fileprivate let instructionsIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "info")
        return imageView
    }()
    
    fileprivate let instructionsLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_SMALL
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "Share to unlock ratings!"
        return label
    }()
    
    func shareOnFb() {
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
            //            socialController.setInitialText("Hello World!")
            //            socialController.addImage(someUIImageInstance)
            //            socialController.addURL(someNSURLInstance)
            self.present(socialController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "Rating Results"
        self.setupViews()
        self.loadData()
    }
    
    fileprivate func loadData() {
        // TODO: Randomly load a do you know? 
        self.didYouKnowText.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        self.didYouKnowText.flashScrollIndicators()
        
    }
    
    fileprivate func setupViews() {
        self.edgesForExtendedLayout = []
        
        let didYouKnowContainer = UIView()
        didYouKnowContainer.addSubview(didYouKnowLbl)
        didYouKnowContainer.addSubview(didYouKnowText)
        didYouKnowContainer.backgroundColor = GRAY_UICOLOR
        didYouKnowContainer.addConstraintsWithFormat("V:|-8-[v0(25)]-8-[v1]-8-|", views: didYouKnowLbl, didYouKnowText)
        didYouKnowContainer.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: didYouKnowLbl)
        didYouKnowContainer.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: didYouKnowText)
        didYouKnowContainer.layer.cornerRadius = 5.0
        
        let instructionsContainer = UIView()
        instructionsContainer.addSubview(instructionsIcon)
        instructionsContainer.addSubview(instructionsLbl)
        instructionsContainer.translatesAutoresizingMaskIntoConstraints = false
        instructionsContainer.addConstraintsWithFormat("H:|[v0(14)]-4-[v1]|", views: instructionsIcon, instructionsLbl)
        instructionsContainer.addConstraintsWithFormat("V:|[v0(14)]", views: instructionsIcon)
        instructionsContainer.addConstraintsWithFormat("V:|-1-[v0(14)]|", views: instructionsLbl)
        view.addSubview(instructionsContainer)
        view.addConstraint(NSLayoutConstraint(item: instructionsContainer, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        
        view.addSubview(didYouKnowContainer)
        view.addSubview(fbButton)
        view.addSubview(instructionsContainer)
        
        view.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: didYouKnowContainer)
        view.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: fbButton)
        view.addConstraintsWithFormat("V:|-12-[v0(250)]-12-[v1(40)]-8-[v2(40)]", views: didYouKnowContainer, fbButton, instructionsContainer)
        
    }
    
    
}
