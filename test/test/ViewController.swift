//
//  ViewController.swift
//  test
//
//  Created by Leonard Loo on 10/15/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit
extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        _ = _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    func addAndGetConstraintsWithFormat(_ format: String, views: UIView...) -> [NSLayoutConstraint] {
        return _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    fileprivate func _addAndGetConstraintsWithFormat(_ format: String, views: [UIView]) -> [NSLayoutConstraint] {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        let constraints_ = NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary)
        addConstraints(constraints_)
        return constraints_
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blue
        let scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.backgroundColor = UIColor.gray
        
        
        let containerView = UIView()
        scrollView.addSubview(containerView)
        view.addSubview(scrollView)
        self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0))
        scrollView.addConstraintsWithFormat("H:|[v0]|", views: containerView)
        scrollView.addConstraintsWithFormat("V:|[v0]|", views: containerView)
        
        containerView.addSubview(label1)
        containerView.addSubview(label2)
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: label1)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: label2)
        containerView.addConstraintsWithFormat("V:|[v0]-[v1]|", views: label1, label2)
        
        
        self.view.addConstraintsWithFormat("H:|[v0]|", views: scrollView)
        self.view.addConstraintsWithFormat("V:|[v0]|", views: scrollView)
    }

    
    

    
    fileprivate let label1: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = UIColor.black
        label.text = "Hello world hello world! Hey how are you? I'm good. Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good.Hello world hello world! Hey how are you? I'm good."
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let label2: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30.0)
        label.textColor = UIColor.red
        label.text = "I'M BOLD!!!"
        return label
    }()


}

