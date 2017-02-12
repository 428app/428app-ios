//
//  ClassroomCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ClassroomCell: BaseCollectionCell {
    
    // MARK: Set up views
    fileprivate var classroom: Classroom!
    
    fileprivate let classroomImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizesSubviews = true
        return imageView
    }()
    
    fileprivate let updatedLbl: UILabel = {
        let label = UILabel()
        label.backgroundColor = RED_UICOLOR
        label.text = "Updated"
        label.font = FONT_HEAVY_SMALL
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.isHidden = true
        return label
    }()
    
    fileprivate let titleLbl: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.white
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let questionNumLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_LARGE
        label.textColor = UIColor.white
        label.textAlignment = .center
        return label
    }()
    
    override func setupViews() {
        
        let containerView = UIView()
        containerView.layer.cornerRadius = 7.0
        let SHADOW_COLOR: CGFloat =  157.0 / 255.0
        containerView.layer.shadowColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).cgColor
        containerView.layer.shadowOpacity = 0.6
        containerView.layer.shadowRadius = 4.0
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        self.backgroundColor = GRAY_UICOLOR
        contentView.backgroundColor = GRAY_UICOLOR
        containerView.backgroundColor = RED_UICOLOR
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        contentView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: containerView)
        contentView.addConstraintsWithFormat("V:|-8-[v0]-8-|", views: containerView)
        
        containerView.addSubview(classroomImageView)
        containerView.addSubview(updatedLbl)
        containerView.addSubview(titleLbl)
        containerView.addSubview(questionNumLbl)
        
        containerView.addConstraintsWithFormat("V:|[v0(175)]-12-[v1(25)]-5-[v2]-|", views: classroomImageView, titleLbl, questionNumLbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: classroomImageView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: titleLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionNumLbl)
        
        containerView.addConstraint(NSLayoutConstraint(item: updatedLbl, attribute: .bottom, relatedBy: .equal, toItem: classroomImageView, attribute: .bottom, multiplier: 1.0, constant: -8.0))
        containerView.addConstraint(NSLayoutConstraint(item: updatedLbl, attribute: .right, relatedBy: .equal, toItem: classroomImageView, attribute: .right, multiplier: 1.0, constant: -8.0))
        containerView.addConstraintsWithFormat("V:[v0(25)]", views: updatedLbl)
        containerView.addConstraintsWithFormat("H:[v0(80)]", views: updatedLbl)

    }
    
    fileprivate func loadImage() {
        // Loads image asynchronously and efficiently
        
        let imageUrlString = self.classroom.imageName
        self.classroomImageView.af_cancelImageRequest()
        guard let imageUrl = URL(string: imageUrlString) else {
            self.classroomImageView.image = UIImage.init(color: UIColor.white)
            return
        }
        
        self.classroomImageView.af_setImage(withURL: imageUrl, placeholderImage: UIImage.init(color: UIColor.white), filter: nil, progress: nil, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false, completion: { imageResponse in
            // Image finished downloading, so cache it - this is mostly for push notifications, as internally af_setImage already has its own cache
            if let imageData = imageResponse.data, let image = UIImage(data: imageData) {
                imageCache.add(image, withIdentifier: imageUrl.absoluteString)
            }
        })
    }
    
    func configureCell(classroom: Classroom) {
        self.classroom = classroom
        self.updatedLbl.isHidden = !classroom.hasUpdates
        self.loadImage()
        self.titleLbl.text = self.classroom.title
        self.questionNumLbl.text = "Current Question: \(self.classroom.questionNum)"
    }
    
}
