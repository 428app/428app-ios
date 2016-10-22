//
//  LoginController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/20/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class LoginController: UIViewController, UIScrollViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GRAY_UICOLOR
        scrollView.delegate = self
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if justFinishedIntro {
            justFinishedIntro = false
            let controller = CustomTabBarController()
            controller.modalTransitionStyle = .coverVertical
            self.present(controller, animated: true, completion: nil)
        }
        super.viewWillAppear(animated)
    }
    
    fileprivate lazy var loginButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = FONT_MEDIUM_LARGE
        button.setTitle("Log in with Facebook", for: .normal)
        button.setBackgroundColor(color: FB_BLUE_UICOLOR, forState: .normal)
        button.setBackgroundColor(color: FB_BLUE_UICOLOR.withAlphaComponent(0.8), forState: .highlighted)
        button.addTarget(self, action: #selector(fbLogin), for: .touchUpInside)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 3.0
        button.clipsToBounds = true
        return button
    }()
    
    func fbLogin() {
        // TODO: Integrate FB Login
        let controller = isFirstTimeUser ? IntroController() : CustomTabBarController()
        controller.modalTransitionStyle = .coverVertical
        self.present(controller, animated: true, completion: nil)
    }
    
    fileprivate let warningLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_SMALL
        label.textColor = UIColor.darkGray
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        paragraphStyle.alignment = .center
        let str1 = NSMutableAttributedString(string: "By continuing, you agree to our ", attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        let str2 = NSMutableAttributedString(string: "Terms of Service", attributes: [NSFontAttributeName: FONT_HEAVY_SMALL])
        let str3 = NSMutableAttributedString(string: " and ")
        let str4 = NSMutableAttributedString(string: "Privacy Policy", attributes: [NSFontAttributeName: FONT_HEAVY_SMALL])
        str1.append(str2)
        str1.append(str3)
        str1.append(str4)
        label.attributedText = str1
        
        return label
    }()
    
    fileprivate let fbDisclaimerIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "info")
        return imageView
    }()
    
    fileprivate let fbDisclaimerLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_SMALL
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "We do not post anything to Facebook."
        return label
    }()
    
    // MARK: Sliders
    
    fileprivate let scrollView: UIScrollView = {
        let frame = UIScreen.main.bounds
        // Scroll view width and height set according to constraints defined in setupViews
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width - 40, height: frame.height - 205))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    fileprivate lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = self.sliderViews.count
        control.currentPage = 0
        control.tintColor = UIColor.lightGray
        control.pageIndicatorTintColor = UIColor.lightGray
        control.currentPageIndicatorTintColor = UIColor.darkGray
        return control
    }()
    
    fileprivate let slider1View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "LoginSlider1")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    fileprivate let slider2View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "LoginSlider2")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    var sliderViews: [UIImageView] = []
    var colors: [UIColor] = [UIColor.red, UIColor.blue]
    var frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    func changePage(sender: AnyObject) -> () {
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    // Delegate function that changes pageControl when scrollView scrolls
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
    
    fileprivate func setupViews() {
        sliderViews.append(slider1View)
        sliderViews.append(slider2View)
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(warningLabel)
        view.addSubview(loginButton)
        
        for index in 0..<2 {
            frame.origin.x = self.scrollView.frame.size.width * CGFloat(index)
            frame.size = self.scrollView.frame.size
            let subView = self.sliderViews[index]
            subView.frame = frame
            self.scrollView.addSubview(subView)
        }
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(sliderViews.count), height: self.scrollView.frame.size.height)
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: pageControl)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: scrollView)

        let disclaimerContainer = UIView()
        disclaimerContainer.addSubview(fbDisclaimerIcon)
        disclaimerContainer.addSubview(fbDisclaimerLabel)
        disclaimerContainer.translatesAutoresizingMaskIntoConstraints = false
        disclaimerContainer.addConstraintsWithFormat("H:|[v0(14)]-4-[v1]|", views: fbDisclaimerIcon, fbDisclaimerLabel)
        disclaimerContainer.addConstraintsWithFormat("V:|[v0(14)]", views: fbDisclaimerIcon)
        disclaimerContainer.addConstraintsWithFormat("V:|-1-[v0(14)]|", views: fbDisclaimerLabel)
        view.addSubview(disclaimerContainer)
        view.addConstraint(NSLayoutConstraint(item: disclaimerContainer, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        
        view.addConstraint(NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        view.addConstraintsWithFormat("V:[v0][v1(30)]-2-[v2(45)]-8-[v3(45)]-15-[v4]-15-|", views: scrollView, pageControl, warningLabel, loginButton, disclaimerContainer)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: warningLabel)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: loginButton)
    }
}
