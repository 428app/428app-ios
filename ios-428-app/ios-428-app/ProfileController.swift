//
//  ProfileController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/16/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit


class ProfileController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    var profile: Profile! {
        didSet { // Set from ChatController's openProfile
            self.assembleCellData()
        }
    }
    
    fileprivate let CELL_ID = "profileCell"
//    fileprivate let HEIGHT_OF_CELL: CGFloat = 40.0
    fileprivate var profileCellTitles = [String]()
    fileprivate var profileCellContent = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.setupTableView()
//        self.setupCollectionView()
        self.setupViews()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Set up views
    
    fileprivate let profileBgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    fileprivate let closeButton: UIButton = {
        let button = UIButton()
        button.tintColor = UIColor.white
        button.setImage(#imageLiteral(resourceName: "down"), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()
    
    fileprivate let closeButtonBg: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "downbg").alpha(value: 0.45)
        imageView.contentMode = .scaleAspectFill
        return imageView
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
    
    fileprivate let nameLbl: UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.black
        return label
    }()
    
    fileprivate let disciplineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = GREEN_UICOLOR
        return imageView
    }()
    
    fileprivate let ageLocationLbl: UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        return label
    }()
    
    fileprivate let topDividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.white
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.bounces = false
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    fileprivate let bottomDividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    fileprivate let tagline1Lbl: UILabel = {
       let label = UILabel()
        label.numberOfLines = 0
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let tagline2Lbl: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }()
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileCell.self, forCellReuseIdentifier: CELL_ID)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 50.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable top bounce only, and not bottom bounce
        if (scrollView.contentOffset.y <= 0) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }

    fileprivate func setupViews() {
        // Set up scroll view, and close button on top of scroll view
        let scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.delegate = self // Delegate so as to disable top bounce only
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        let containerView = UIView()
        scrollView.addSubview(containerView)
        view.addSubview(scrollView)
        view.addConstraintsWithFormat("H:|[v0]|", views: scrollView)
        view.addConstraintsWithFormat("V:|[v0]|", views: scrollView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0))
        scrollView.addConstraintsWithFormat("H:|[v0]|", views: containerView)
        scrollView.addConstraintsWithFormat("V:|[v0]|", views: containerView)
        view.addSubview(closeButtonBg)
        view.addSubview(closeButton)
        view.addConstraintsWithFormat("H:|-15-[v0(30)]", views: closeButtonBg)
        view.addConstraintsWithFormat("V:|-15-[v0(30)]", views: closeButtonBg)
        view.addConstraintsWithFormat("H:|-10-[v0(40)]", views: closeButton)
        view.addConstraintsWithFormat("V:|-9-[v0(40)]", views: closeButton)
        closeButton.addTarget(self, action: #selector(closeProfile), for: .touchUpInside)
        
        // Set values for elements in scroll view
        profileBgImageView.image = UIImage(named: profile.disciplineBgName)
        profileImageView.image = UIImage(named: profile.profileImageName)
        nameLbl.text = profile.name
        disciplineImageView.image = UIImage(named: profile.disciplineImageName)
        ageLocationLbl.text = "\(profile.age), \(profile.location)"
        
        // Taglines
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let tagstr1 = NSMutableAttributedString(string: "I am working on", attributes: [NSForegroundColorAttributeName: GREEN_UICOLOR, NSFontAttributeName: FONT_HEAVY_MID, NSParagraphStyleAttributeName: paragraphStyle])
        let tagline1 = NSMutableAttributedString(string: " " + profile.tagline1, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        tagstr1.append(tagline1)
        tagline1Lbl.attributedText = tagstr1
        
        let tagstr2 = NSMutableAttributedString(string: "I want to eventually", attributes: [NSForegroundColorAttributeName: GREEN_UICOLOR, NSFontAttributeName: FONT_HEAVY_MID, NSParagraphStyleAttributeName: paragraphStyle])
        let tagline2 = NSMutableAttributedString(string: " " + profile.tagline2, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        tagstr2.append(tagline2)
        tagline2Lbl.attributedText = tagstr2
        
        // Add to subviews
        containerView.addSubview(profileBgImageView)
        containerView.addSubview(profileImageView)
        
        // Centered discipline icon and name label
        let nameDisciplineContainer = UIView()
        nameDisciplineContainer.addSubview(disciplineImageView)
        nameDisciplineContainer.addSubview(nameLbl)
        nameDisciplineContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameDisciplineContainer)
        containerView.addConstraint(NSLayoutConstraint(item: nameDisciplineContainer, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        nameDisciplineContainer.addConstraintsWithFormat("H:|[v0(20)]-5-[v1]|", views: disciplineImageView, nameLbl)
        nameDisciplineContainer.addConstraintsWithFormat("V:|[v0(20)]", views: disciplineImageView)
        nameDisciplineContainer.addConstraintsWithFormat("V:|[v0(25)]|", views: nameLbl)
        
        containerView.addSubview(ageLocationLbl)
        containerView.addSubview(topDividerLineView)
        containerView.addSubview(tableView)
        containerView.addSubview(bottomDividerLineView)
        containerView.addSubview(tagline1Lbl)
        containerView.addSubview(tagline2Lbl)
        
        // Define constraints
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: profileBgImageView)
        containerView.addConstraintsWithFormat("V:|[v0(250)]", views: profileBgImageView)
        
        
        containerView.addConstraintsWithFormat("H:[v0(150)]", views: profileImageView)
        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: ageLocationLbl)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: topDividerLineView)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: bottomDividerLineView)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: tagline1Lbl)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: tagline2Lbl)
        
        UIView.animate(withDuration: 0, animations: { 
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.tableView.invalidateIntrinsicContentSize()
            }) { (completed) in
                let heightOfTableView = self.tableView.contentSize.height
                
                let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
                containerView.addConstraintsWithFormat("V:|-175-[v0(150)]-10-[v1]-6-[v2(20)]-10-[v3(0.5)]-10-[v4(\(heightOfTableView))]-10-[v5(0.5)]-10-[v6]-20-[v7]-\(bottomMargin)-|", views: self.profileImageView, nameDisciplineContainer, self.ageLocationLbl, self.topDividerLineView, self.tableView, self.bottomDividerLineView, self.tagline1Lbl, self.tagline2Lbl)
                containerView.addConstraintsWithFormat("H:|[v0]|", views: self.tableView)
        }
        
    }
    
    func closeProfile(button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Table view
    
    fileprivate func assembleCellData() {
        self.profileCellTitles = ["Organization", "School", "Discipline"]
        self.profileCellContent = [self.profile.org, self.profile.school, self.profile.discipline]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileCellTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! ProfileCell
        let cellTitle = self.profileCellTitles[indexPath.row]
        let cellContent = self.profileCellContent[indexPath.row]
        cell.configureCell(title: cellTitle, content: cellContent)
        return cell
    }
    
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return profileCellTitles.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: self.view.frame.width, height: HEIGHT_OF_CELL)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ProfileCell
//        let cellTitle = self.profileCellTitles[indexPath.row]
//        let cellContent = self.profileCellContent[indexPath.row]
//        cell.configureCell(title: cellTitle, content: cellContent)
//        return cell
//    }
}
