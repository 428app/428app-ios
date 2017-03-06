//
//  MeController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/20/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Social

class MeController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "Me"
        self.setupViews()
        self.loadShareFirst()
        self.setupTabBarIcons() // As this is the landing page for an app launch, tab bar notifications will be nested here
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        self.registerObservers()
        self.loadData() // Load data has to be here
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // This code has to be here and not in viewDidAppear, etc.
        if isFirstTimeUser {
            showNewUserAlert()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.unregisterObservers()
    }
    
    fileprivate func setupTabBarIcons() {
        DataService.ds.observeNewInboxForTabBar { (count) in
            if #available(iOS 10.0, *) {
                self.tabBarController?.tabBar.items?.last?.badgeColor = RED_UICOLOR
            }
            self.tabBarController?.tabBar.items?.last?.badgeValue = count > 0 ? "\(count)" : nil
        }
        
        DataService.ds.observeNewPlaygroupForTabBar { (shouldShowIcon) in
            if let tabController = self.tabBarController as? CustomTabBarController, let tabItems = tabController.tabBar.items {
                if tabItems.count > 2 { // Must have at least 3 tabs, although we are accessing the second tab
                    if #available(iOS 10.0, *) {
                        tabItems[1].badgeColor = RED_UICOLOR
                    }
                    tabItems[1].badgeValue = shouldShowIcon ? "!!" : nil
                }
            }
        }
    }
    
    // This is loaded first upon view appearing so there would be no wait time when user clicks Share on FB on other parts of the app
    fileprivate func loadShareFirst() {
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                socialController.add(#imageLiteral(resourceName: "logo"))
                self.present(socialController, animated: false, completion: {
                    // Dismiss immediately after presented
                    socialController.dismiss(animated: false, completion: nil)
                })
            }
        }
    }
    
    fileprivate func showNewUserAlert() {
        let alertController = NewUserAlertController()
        alertController.modalPresentationStyle = .overFullScreen
        alertController.modalTransitionStyle = .crossDissolve
        self.present(alertController, animated: true, completion: nil)
    }
    
    func openProfileIconModal(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: String], let iconImageName = userInfo["iconImageName"] {
            let discipline = getDisciplineName(iconImageName: iconImageName)
            let disciplineDescription = getDisciplineDescription(discipline: discipline)
            let controller = UIAlertController(title: discipline, message: disciplineDescription, preferredStyle: .alert)
            self.present(controller, animated: true, completion: {
                controller.view.superview?.isUserInteractionEnabled = true
                let tapToDismissModal = UITapGestureRecognizer(target: self, action: #selector(self.dismissProfileIconModal))
                controller.view.superview?.addGestureRecognizer(tapToDismissModal)
            })
        }
    }
    
    func dismissProfileIconModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setProfilePic() {
        guard let profilePic = myProfilePhoto else {
            return
        }
        self.profileImageView.isUserInteractionEnabled = true
        self.profileImageView.image = profilePic
    }
    
    func setProfileData() {
        guard let profileData = myProfile else {
            return
        }
        let ageString = profileData.age == nil ? "" : ", \(profileData.age!)"
        self.nameAndAgeLbl.text = "\(profileData.name)\(ageString)"
        self.disciplineImageView.image = UIImage(named: profileData.disciplineIcon)
        self.playgroups = profileData.playgroupIcons
        self.playgroupsCollectionView.reloadData()
    }
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(openProfileIconModal), name: NOTIF_PROFILEICONTAPPED, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setProfilePic), name: NOTIF_MYPROFILEPICDOWNLOADED, object: nil)
    }
    
    fileprivate func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NOTIF_PROFILEICONTAPPED, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_MYPROFILEPICDOWNLOADED, object: nil)
    }
    
    // MARK: Firebase
    
    // Grabs server settings, user profile from Firebase, then downloads profile image
    fileprivate func loadData() {
        
        // Triggered when changes are made in EditProfileController/EditProfessionController and user goes back to MeController
        self.setProfilePic()
        self.setProfileData()
        
        DataService.ds.getUserFields(uid: getStoredUid()) { (isSuccess, profile) in
            if isSuccess && profile != nil {
                
                // Profile photo
                if myProfilePhoto != nil {
                    self.setProfilePic()
                } else {
                    // Download image and set profile pic
                    _ = downloadImage(imageUrlString: profile!.profileImageName, completed: { (image) in
                        if image != nil {
                            myProfilePhoto = image!
                            self.setProfilePic() // This has to come after setting myProfilePhoto
                        }
                    })
                }
                
                // Discipline, name and age
                myProfile = profile!
                self.setProfileData()
                
                if self.playgroups.count == 0 {
                    self.noPlaygroupsLbl.isHidden = false
                    self.containerView.addSubview(self.noPlaygroupsLbl)
                    self.containerView.addConstraint(NSLayoutConstraint(item: self.noPlaygroupsLbl, attribute: .top, relatedBy: .equal, toItem: self.playgroupsLbl, attribute: .bottom, multiplier: 1.0, constant: 8.0))
                    self.containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: self.noPlaygroupsLbl)
                } else {
                    self.noPlaygroupsLbl.isHidden = true
                }
            }
        }
        
    }
    
    // MARK: Views 0 - Profile image, cover image
    
    fileprivate lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizesSubviews = true
        imageView.clipsToBounds = true
        imageView.image = UIImage(color: UIColor.white)
        return imageView
    }()
    
    fileprivate lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = #imageLiteral(resourceName: "placeholder-user")
        imageView.layer.borderColor = RED_UICOLOR.cgColor
        imageView.layer.borderWidth = 4.0
        imageView.layer.cornerRadius = 90.0 // Actual image size is 180.0 so this is /2
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.addGestureRecognizer(self.picTap)
        return imageView
    }()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func expandPic() {
        logAnalyticsEvent(key: kEventViewPhotoOnMe)
        let pictureModalController = PictureModalController()
        pictureModalController.picture = self.profileImageView.image
        pictureModalController.modalPresentationStyle = .overFullScreen
        pictureModalController.modalTransitionStyle = .crossDissolve
        self.present(pictureModalController, animated: true, completion: nil)
    }
    
    fileprivate lazy var picTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(ProfileController.expandPic))
        tap.delegate = self
        return tap
    }()
    
    // MARK: Views 1 - Discipline icon, name and age label
    
    fileprivate let nameAndAgeLbl: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.darkGray
        return label
    }()
    
    fileprivate lazy var disciplineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = RED_UICOLOR
        let tap = UITapGestureRecognizer(target: self, action: #selector(animateDiscipline))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    func animateDiscipline() {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.isAdditive = true
        animation.duration = 0.6
        animation.values = [0, M_PI, 2*M_PI]
        disciplineImageView.layer.add(animation, forKey: "show")
    }

    // MARK: Views 2 - Horizontal collection views of playgroup icons
    
    fileprivate let PLAYGROUPS_CELL_ID = "playgroupsCollectionCell"
    fileprivate var playgroups = [String]()
    
    open static let ICON_SIZE: CGFloat = 33.0

    fileprivate lazy var playgroupsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = true
        return collectionView
    }()
    
    fileprivate func sectionLabelTemplate(labelText: String) -> UILabel {
        let label = UILabel()
        label.text = labelText
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }
    
    fileprivate lazy var playgroupsLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Playgroups")
    }()
    
    fileprivate func setupCollectionView() {
        self.playgroupsCollectionView.delegate = self
        self.playgroupsCollectionView.dataSource = self
        self.playgroupsCollectionView.register(HorizontalScrollCell.self, forCellWithReuseIdentifier: PLAYGROUPS_CELL_ID)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Each of the two collection views only have one section
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Return playgroups collection view
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PLAYGROUPS_CELL_ID, for: indexPath) as! HorizontalScrollCell
        cell.configureCell(icons: playgroups)
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: ProfileController.ICON_SIZE) // Width is defined in HorizontalScrollCell
    }
    
    fileprivate let dividerLineForCollectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    let noPlaygroupsLbl: UILabel = {
        let label = UILabel()
        label.text = "No playgroups yet."
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.gray
        label.textAlignment = .left
        return label
    }()
    
    // MARK: Views 3 - Edit Profile and Settings buttons
    
    fileprivate func meBtnTemplate(btnText: String) -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = FONT_HEAVY_LARGE
        button.titleLabel?.textAlignment = .center
        button.setTitle(btnText, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        button.setBackgroundColor(color: GREEN_UICOLOR, forState: .normal)
        button.setBackgroundColor(color: RED_UICOLOR, forState: .highlighted)
        button.layer.cornerRadius = 5.0
        button.layer.masksToBounds = true
        return button
    }
    
    fileprivate lazy var editProfileBtn: UIButton = {
        let button: UIButton = self.meBtnTemplate(btnText: "Edit Profile")
        button.addTarget(self, action: #selector(openEditProfile), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var settingsBtn: UIButton = {
        let button = self.meBtnTemplate(btnText: "Settings")
        button.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        return button
    }()
    
    func openEditProfile() {
        // Launch EditProfileController which has two sub controllers, EditProfession and EditTagline
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        let controller = EditProfileController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func openSettings() {
        // Launch SettingsController
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        let controller = SettingsController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable top bounce only, and not bottom bounce
        if (scrollView.contentOffset.y <= 0) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    fileprivate var containerView: UIView!
    
    fileprivate func setupViews() {
        // Set up scroll view, and close button on top of scroll view
        let views = setupScrollView()
        let scrollView = views[0] as! UIScrollView
        containerView = views[1]
        scrollView.delegate = self // Delegate so as to disable top bounce only
        
        // Assign delegate, data source and setup cells for and playgroups collection view
        self.setupCollectionView()
        containerView.isUserInteractionEnabled = true
        // Centered discipline icon and name label
        let disciplineNameAgeContainer = UIView()
        disciplineNameAgeContainer.isUserInteractionEnabled = true
        disciplineNameAgeContainer.addSubview(disciplineImageView)
        disciplineNameAgeContainer.addSubview(nameAndAgeLbl)
        disciplineNameAgeContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(disciplineNameAgeContainer)
        containerView.addConstraint(NSLayoutConstraint(item: disciplineNameAgeContainer, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        disciplineNameAgeContainer.addConstraintsWithFormat("H:|[v0(25)]-5-[v1]|", views: disciplineImageView, nameAndAgeLbl)
        disciplineNameAgeContainer.addConstraintsWithFormat("V:|[v0(25)]", views: disciplineImageView)
        disciplineNameAgeContainer.addConstraintsWithFormat("V:|[v0(25)]|", views: nameAndAgeLbl)
        
        // Add to subviews
        containerView.addSubview(coverImageView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(playgroupsLbl)
        containerView.addSubview(playgroupsCollectionView)
        containerView.addSubview(editProfileBtn)
        containerView.addSubview(settingsBtn)
        containerView.addSubview(dividerLineForCollectionView)
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
        
        // Define main constraints
        let navBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: coverImageView)
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight)-[v0(220)][v1]-8-[v2(20)]-8-[v3(\(ProfileController.ICON_SIZE))]-13-[v4(0.5)]-12-[v5(50)]-[v6(50)]-\(bottomMargin)-|", views: coverImageView, disciplineNameAgeContainer, playgroupsLbl, playgroupsCollectionView, dividerLineForCollectionView, editProfileBtn, settingsBtn)
        
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: playgroupsLbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: playgroupsCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: dividerLineForCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: editProfileBtn)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: settingsBtn)
        
        containerView.addConstraintsWithFormat("H:[v0(180)]", views: profileImageView)
        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight + 35)-[v0(180)]", views: profileImageView)
    }
    
}
