//
//  EditProfileController.swift
//  ios-428-app
//
//  This class is very similar to ProfileController, except with added Edit functionality.
//  Created by Leonard Loo on 10/18/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class EditProfileController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var profile: Profile!
    
    fileprivate let CELL_ID = "editProfileCell"
    fileprivate var heightOfTableViewConstraint: NSLayoutConstraint! // Used to find dynamic height of UITableView
    fileprivate var profileCellTitles = [String]()
    fileprivate var profileCellContent = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Edit Profile"
        self.view.backgroundColor = UIColor.white
        self.automaticallyAdjustsScrollViewInsets = false
        self.loadProfileData()
        self.setupTableView()
        self.setupViews()
    }
    
    fileprivate func loadProfileData() {
        // TODO: Pull profile from server
        profile = yihangprof
    }
    
    // Design is similar to ProfileController, except with Edit functionality
    // MARK: Set up views
    
    fileprivate let profileBgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizesSubviews = true
        imageView.clipsToBounds = true
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable top bounce only, and not bottom bounce
        if (scrollView.contentOffset.y <= 0) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // TODO: Test height of profile bg
        log.info("Height: \(self.profileBgImageView.frame.height), y: \(self.profileBgImageView.frame.origin.y)")
    }
    
    fileprivate func setupViews() {
        // Set up scroll view, and close button on top of scroll view
        let views = setupScrollView()
        let scrollView = views[0] as! UIScrollView
        let containerView = views[1]
        scrollView.delegate = self // Delegate so as to disable top bounce only
        
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
        
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
        
        heightOfTableViewConstraint = NSLayoutConstraint(item: self.tableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1000)
        containerView.addConstraint(heightOfTableViewConstraint)
        containerView.addConstraintsWithFormat("V:|-175-[v0(150)]-10-[v1]-6-[v2(20)]-10-[v3(0.5)]-10-[v4]-10-[v5(0.5)]-10-[v6]-20-[v7]-\(bottomMargin)-|", views: self.profileImageView, nameDisciplineContainer, self.ageLocationLbl, self.topDividerLineView, self.tableView, self.bottomDividerLineView, self.tagline1Lbl, self.tagline2Lbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: self.tableView)
        
        UIView.animate(withDuration: 0, animations: {
            self.tableView.layoutIfNeeded()
        }) { (complete) in
            var heightOfTableView: CGFloat = 0.0
            let cells = self.tableView.visibleCells
            for cell in cells {
                heightOfTableView += cell.frame.height
            }
            self.heightOfTableViewConstraint.constant = heightOfTableView
        }
        
    }
    
    // MARK: Table view
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileCell.self, forCellReuseIdentifier: CELL_ID)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 50.0
        tableView.rowHeight = UITableViewAutomaticDimension
        self.assembleCellData()
    }
    
    fileprivate func assembleCellData() {
        self.profileCellTitles = ["Organization", "School", "Discipline"]
        self.profileCellContent = [self.profile.org, self.profile.school, self.profile.discipline]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
}