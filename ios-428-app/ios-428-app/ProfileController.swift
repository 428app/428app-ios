//
//  ProfileController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/16/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ProfileController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let CELL_ID = "profileCell"
    var profile: Profile! // Set from ChatController's openProfile
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.setupViews()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate let profileBgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    fileprivate let closeButton: UIButton = {
        let button = UIButton()
        button.tintColor = UIColor.white
        button.setImage(#imageLiteral(resourceName: "down"), for: .normal)
        var bgImage = #imageLiteral(resourceName: "downbg").alpha(value: 0.45)
        button.setBackgroundImage(bgImage, for: .normal)
        return button
    }()
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 1.5
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.75
        imageView.layer.shadowRadius = 3.0
        imageView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        return imageView
    }()
    
    fileprivate let nameAgeLbl: UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.black
        return label
    }()
    
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    // MARK: View set up 
    
    fileprivate func setupViews() {
        profileBgImageView.image = UIImage(named: profile.disciplineBgName)
        profileImageView.image = UIImage(named: profile.profileImageName)
        nameAgeLbl.text = "\(profile.name), \(profile.age)"
        
        closeButton.addTarget(self, action: #selector(closeProfile), for: .touchUpInside)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ProfileCell.self, forCellWithReuseIdentifier: CELL_ID)
//        self.automaticallyAdjustsScrollViewInsets = false
        
        self.view.addSubview(profileBgImageView)
        self.view.addSubview(closeButton)
        self.view.addSubview(profileImageView)
        self.view.addSubview(nameAgeLbl)
        self.view.addSubview(collectionView)
        
        self.view.addConstraintsWithFormat("H:|[v0]|", views: profileBgImageView)
        self.view.addConstraintsWithFormat("V:|[v0(250)]", views: profileBgImageView)
        
        self.view.addConstraintsWithFormat("H:|-8-[v0(27)]", views: closeButton)
        self.view.addConstraintsWithFormat("V:|-8-[v0(27)]", views: closeButton)
        
        self.view.addConstraintsWithFormat("H:[v0(150)]", views: profileImageView)
        self.view.addConstraintsWithFormat("V:|-175-[v0(150)]", views: profileImageView)
        self.view.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        self.view.addConstraintsWithFormat("H:|-[v0]-|", views: nameAgeLbl)
        self.view.addConstraintsWithFormat("V:[v0]-8-[v1(30)]-8-[v2(200)]", views: profileImageView, nameAgeLbl, collectionView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        
        
    }
    
    func closeProfile(button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Table view
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 40.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ProfileCell
        return cell
    }
    
    
}
