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

    open var ratingName: String!
    open var userVotedFor: Profile!
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
        tblView.separatorStyle = .none
        tblView.register(VoteCell.self, forCellReuseIdentifier: self.CELL_ID)
        return tblView
    }()
    
    fileprivate lazy var voteLbl: UILabel = {
       let label = UILabel()
        label.textColor = GREEN_UICOLOR
        label.font = FONT_HEAVY_XLARGE
        label.textAlignment = .center
        if let rating = self.ratingName {
            label.text = rating
        }
        return label
    }()
    
    func dismissScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
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
        
        containerView.addSubview(voteLbl)
        containerView.addSubview(tableView)
        
        containerView.addConstraintsWithFormat("V:|-12-[v0(20)]-8-[v1]|", views: voteLbl, tableView)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: voteLbl)
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let classmate = classmates[indexPath.item]
        // If profile is same as user voted for, set selected
        if self.userVotedFor != nil {
            if classmate.uid == self.userVotedFor.uid {
                cell.setSelected(true, animated: false)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let classmate = classmates[indexPath.item]
        self.userVotedFor = classmate
        
        // Select and deselect all rows
        for i in 0...tableView.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: i, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            tableView.deselectRow(at: indexPath, animated: false)
        }
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        
        NotificationCenter.default.post(name: NOTIF_RATINGSELECTED, object: nil, userInfo: ["ratingName": self.ratingName, "userVotedFor": classmate])
        self.dismissScreen()
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
    
    fileprivate let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.3)
        return view
    }()
    
    override func setupViews() {
        backgroundColor = UIColor.white
        
        addSubview(profileImageView)
        addSubview(nameLbl)
        addSubview(dividerView)
        
        addConstraintsWithFormat("H:|-8-[v0(60)]-8-[v1]", views: profileImageView, nameLbl)
        addConstraintsWithFormat("V:|-8-[v0(60)]-8-[v1(0.5)]|", views: profileImageView, dividerView)
        addConstraintsWithFormat("H:|-8-[v0]-8-|", views: dividerView)
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
    
    
    fileprivate func setHighlighted(highlighted: Bool) {
        if highlighted {
            self.nameLbl.textColor = UIColor.white
            self.backgroundColor = GREEN_UICOLOR
            self.profileImageView.layer.borderColor = UIColor.white.cgColor
            self.profileImageView.layer.borderWidth = 2.0
        } else {
            self.nameLbl.textColor = UIColor.darkGray
            self.backgroundColor = UIColor.white
            self.profileImageView.layer.borderColor = UIColor.clear.cgColor
            self.profileImageView.layer.borderWidth = 0.0
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setHighlighted(highlighted: highlighted)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        setHighlighted(highlighted: selected)
    }
    
}
