//
//  PictureModalController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/18/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class PictureModalController: UIViewController {
    
    var picture: UIImage? {
        didSet {
            pictureImageView.image = picture
        }
    }
    
    fileprivate let pictureImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
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
    
    fileprivate func setupViews() {
        view.addSubview(pictureImageView)
        view.addConstraintsWithFormat("H:|[v0]|", views: pictureImageView)
        view.addConstraint(NSLayoutConstraint(item: pictureImageView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0))
    }
}
