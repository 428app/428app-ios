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
    
    fileprivate let disciplineBg: UIView = {
        let view = UIView()
        view.backgroundColor = GREEN_UICOLOR
        view.layer.borderWidth = 3.0
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.cornerRadius = 20.0
        view.clipsToBounds = true
        return view
    }()
    
    fileprivate let disciplineIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func setupViews() {
        backgroundColor = RED_UICOLOR
        addSubview(profileImageView)
        addSubview(disciplineBg)
        addSubview(disciplineIcon)
        addSubview(nameLbl)
        addConstraintsWithFormat("H:[v0(120)]", views: profileImageView)
        addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: disciplineBg, attribute: .bottom, relatedBy: .equal, toItem: profileImageView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: disciplineBg, attribute: .right, relatedBy: .equal, toItem: profileImageView, attribute: .right, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: disciplineIcon, attribute: .centerX, relatedBy: .equal, toItem: disciplineBg, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: disciplineIcon, attribute: .centerY, relatedBy: .equal, toItem: disciplineBg, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        addConstraintsWithFormat("H:[v0(40)]", views: disciplineBg)
        addConstraintsWithFormat("V:[v0(40)]", views: disciplineBg)
        addConstraintsWithFormat("H:[v0(20)]", views: disciplineIcon)
        addConstraintsWithFormat("V:[v0(20)]", views: disciplineIcon)
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
        disciplineIcon.image = UIImage(named: getDisciplineIcon(discipline: self.profile.discipline))
        loadImage()
        self.nameLbl.text = profile.name
    }
}
