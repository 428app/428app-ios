//
//  ModalVoteController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ModalVoteController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate let CELL_ID = "voteCell"
    
    open var classmates: [Profile]!
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    fileprivate lazy var tableView: UITableView = {
       let tblView = UITableView()
        tblView.showsHorizontalScrollIndicator = false
        tblView.bounces = false
        tblView.backgroundColor = UIColor.white
        tblView.delegate = self
        tblView.dataSource = self
        tblView.register(VoteCell.self, forCellReuseIdentifier: self.CELL_ID)
        return tblView
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Table view flash scroll indicators
        tableView.flashScrollIndicators()
    }
    
    fileprivate func setupViews() {
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraintsWithFormat("V:|-88-[v0]-88-|", views: containerView)
        
        containerView.addSubview(tableView)
        
        containerView.addConstraintsWithFormat("V:|[v0]|", views: tableView)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: tableView)
    }
    
    // MARK: Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return classmates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! VoteCell
        let classmate = classmates[indexPath.item]
        cell.configureCell(profileObj: classmate)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let classmate = classmates[indexPath.item]
        log.info("Selected row: \(classmate.name)")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
}



class VoteCell: BaseTableViewCell {
    
    fileprivate var profile: Profile!
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30 // Width and height of 60.0 so /2
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
        backgroundColor = UIColor.white
        selectedBackgroundView = UIView(frame: self.bounds)
        selectedBackgroundView?.backgroundColor = GREEN_UICOLOR
        
        addSubview(profileImageView)
        addSubview(nameLbl)
        
        addConstraintsWithFormat("H:|-8-[v0(60)]-8-[v1]", views: profileImageView, nameLbl)
        addConstraintsWithFormat("V:|-8-[v0(60)]-8-|", views: profileImageView)
        addConstraintsWithFormat("V:[v0(30)]", views: nameLbl)
        addConstraint(NSLayoutConstraint(item: nameLbl, attribute: .centerY, relatedBy: .equal, toItem: profileImageView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
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
    
    func configureCell(profileObj: Profile) {
        self.profile = profileObj
        loadImage(imageUrlString: profile.profileImageName)
        nameLbl.text = profile.name
    }
}
