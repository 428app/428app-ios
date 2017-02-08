//
//  SuperlativeCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class SuperlativeCell: BaseCollectionCell {
    
    fileprivate var superlative: Superlative!
    
    fileprivate let superlativeLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_XLARGE
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 40 // Width and height of 80.0 so /2
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    fileprivate let nameLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }()
    
    override func setupViews() {
        backgroundColor = GREEN_UICOLOR
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.layer.cornerRadius = 4.0
        let SHADOW_COLOR: CGFloat =  157.0 / 255.0
        containerView.layer.shadowColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).cgColor
        containerView.layer.shadowOpacity = 0.6
        containerView.layer.shadowRadius = 2.0
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        containerView.addSubview(superlativeLbl)
        
        // Centered profile image and name label
        let profileContainer = UIView()
        profileContainer.addSubview(profileImageView)
        profileContainer.addSubview(nameLbl)
        profileContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileContainer)
        containerView.addConstraint(NSLayoutConstraint(item: profileContainer, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        profileContainer.addConstraintsWithFormat("H:|[v0(80)]-5-[v1]|", views: profileImageView, nameLbl)
        profileContainer.addConstraintsWithFormat("V:|[v0(80)]|", views: profileImageView)
        profileContainer.addConstraintsWithFormat("V:|-30-[v0(30)]", views: nameLbl)
        
        containerView.addConstraintsWithFormat("V:|-8-[v0(30)]-8-[v1]-8-|", views: superlativeLbl, profileContainer)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: superlativeLbl)
        
        addSubview(containerView)
        addConstraintsWithFormat("H:|-12-[v0]-12-|", views: containerView)
        addConstraintsWithFormat("V:|-8-[v0]-8-|", views: containerView)
        
    }
    
    
    fileprivate func loadImage(imageUrlString: String) {
        // Loads image asynchronously and efficiently
        
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
    
    func configureCell(superlativeObj: Superlative) {
        self.superlative = superlativeObj
        superlativeLbl.text = superlative.superlativeName
        // Get user's
        if let user = superlative.userVotedFor {
            loadImage(imageUrlString: user.profileImageName)
            nameLbl.text = user.name
            nameLbl.textColor = GREEN_UICOLOR
        } else {
            // Set placeholder
            profileImageView.image = #imageLiteral(resourceName: "placeholder-user")
            nameLbl.text = "Vote now"
            nameLbl.textColor = UIColor.darkGray
        }
    }
}
