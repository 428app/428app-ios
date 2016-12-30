//
//  ClassmatesProfileCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ClassmatesProfileCell: BaseCollectionCell {
    
    fileprivate var profile: Profile!
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3.0
        imageView.layer.cornerRadius = 60.0 // Actual image size is 120.0 so this is /2
        imageView.clipsToBounds = true
        return imageView
    }()
    
    fileprivate let nameLbl: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = FONT_HEAVY_LARGE
        label.textAlignment = .center
        return label
    }()
    
    override func setupViews() {
        backgroundColor = GREEN_UICOLOR
        addSubview(profileImageView)
        addSubview(nameLbl)
        addConstraintsWithFormat("H:[v0(120)]", views: profileImageView)
        addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraintsWithFormat("H:|-8-[v0]-8-|", views: nameLbl)
        addConstraintsWithFormat("V:|-8-[v0(120)]-8-[v1]-8-|", views: profileImageView, nameLbl)
    }
    
    fileprivate func loadImage() {
        // Loads image asynchronously and efficiently
        
        let imageUrlString = self.profile.profileImageName
        self.profileImageView.af_cancelImageRequest()
        guard let imageUrl = URL(string: imageUrlString) else {
            self.profileImageView.image = #imageLiteral(resourceName: "placeholder-user")
            return
        }
        
        self.profileImageView.af_setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "placeholder-user"), filter: nil, progress: nil, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false, completion: { imageResponse in
            // Image finished downloading, so cache it - this is mostly for push notifications, as internally af_setImage already has its own cache
            if let imageData = imageResponse.data, let image = UIImage(data: imageData) {
                imageCache.add(image, withIdentifier: imageUrl.absoluteString)
            }
        })
    }
    
    func configureCell(profileObj: Profile) {
        self.profile = profileObj
        loadImage()
        self.nameLbl.text = profile.name
    }
}
