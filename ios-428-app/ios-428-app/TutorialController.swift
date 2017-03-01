//
//  TutorialController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 2/28/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class TutorialController: UIViewController, UIScrollViewDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GRAY_UICOLOR
        scrollView.delegate = self
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Scroll back to first
        pageControl.currentPage = 0
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    // MARK: Sliders
    
    fileprivate let scrollView: UIScrollView = {
        let frame = UIScreen.main.bounds
        // Scroll view width and height set according to constraints defined in setupViews
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width - 40, height: frame.height - 80))
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
        control.currentPageIndicatorTintColor = GREEN_UICOLOR
        return control
    }()
    
    fileprivate let slider1View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "Tutorial-Slider1")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    fileprivate let slider2View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "Tutorial-Slider2")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    fileprivate let slider3View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "Tutorial-Slider3")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    fileprivate let slider4View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "Tutorial-Slider4")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    fileprivate let slider5View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "Tutorial-Slider5")
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
    
    fileprivate lazy var dismissBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("I got this!", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setBackgroundColor(color: GREEN_UICOLOR, forState: .normal)
        btn.setBackgroundColor(color: RED_UICOLOR, forState: .highlighted)
        btn.layer.cornerRadius = 4.0
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(dismissScreen), for: .touchUpInside)
        return btn
    }()
    
    func dismissScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setupViews() {
        sliderViews.append(slider1View)
        sliderViews.append(slider2View)
        sliderViews.append(slider3View)
        sliderViews.append(slider4View)
        sliderViews.append(slider5View)
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(dismissBtn)
        
        for index in 0..<sliderViews.count {
            frame.origin.x = self.scrollView.frame.size.width * CGFloat(index)
            frame.size = self.scrollView.frame.size
            let subView = self.sliderViews[index]
            subView.frame = frame
            self.scrollView.addSubview(subView)
        }
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(sliderViews.count), height: self.scrollView.frame.size.height - 100)
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: pageControl)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: scrollView)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: dismissBtn)
        
        view.addConstraint(NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        view.addConstraintsWithFormat("V:[v0][v1(30)]-8-[v2(45)]-20-|", views: scrollView, pageControl, dismissBtn)
    }
}
