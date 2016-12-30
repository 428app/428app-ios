//
//  ClassmatesController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ClassmatesController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "classmatesProfileCell"
    
    open var classmates: [Profile]!
    
    let interactor = Interactor() // Used for transitioning to and from ProfileController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Classmates"
        self.view.backgroundColor = GREEN_UICOLOR
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
    }
    
    fileprivate func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = GREEN_UICOLOR
        collectionView?.bounces = false
        collectionView?.register(ClassmatesProfileCell.self, forCellWithReuseIdentifier: CELL_ID)
    }
    // MARK: Collection view
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.classmates.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ClassmatesProfileCell
        let classmate = self.classmates[indexPath.item]
        cell.configureCell(profileObj: classmate)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 2 cells per row
        return CGSize(width: UIScreen.main.bounds.width / 2.0, height: 168.0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let classmate = self.classmates[indexPath.item]
        let controller = ProfileController()
        controller.transitioningDelegate = self
        controller.interactor = interactor
        controller.profile = classmate
        controller.modalTransitionStyle = .coverVertical
        controller.modalPresentationStyle = .overFullScreen
        self.present(controller, animated: true, completion: nil)
    }
    
}

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
