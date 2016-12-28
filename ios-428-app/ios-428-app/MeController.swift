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

class MeController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
//    var profile: Profile!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "Me"
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.populateData()
        self.registerObservers()
    }
    
    func openProfileIconModal(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: String], let iconImageName = userInfo["iconImageName"] {
            // TODO: Have to map icon image name to icon description to set in alert title
            let controller = UIAlertController(title: iconImageName, message: "This is how you do it...", preferredStyle: .alert)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.unregisterObservers()
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
        self.nameAndAgeLbl.text = "\(profileData.name), \(profileData.age)"
        self.disciplineImageView.image = UIImage(named: profileData.disciplineIcon)
        // TODO: Badges, and classrooms
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
    fileprivate func populateData() {
        
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
                
            }
        }
    }
    
    // MARK: Views 0 - Profile image, cover image
    
    fileprivate lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizesSubviews = true
        imageView.clipsToBounds = true
        imageView.image = UIImage(color: GRAY_UICOLOR)
        return imageView
    }()
    
    fileprivate lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
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
    
    fileprivate let disciplineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = GREEN_UICOLOR
        return imageView
    }()
    
    // MARK: Views 2 - Horizontal collection views of badge and classroom icons
    
    fileprivate let BADGES_CELL_ID = "badgesCollectionCell"
    fileprivate let CLASSROOMS_CELL_ID = "classroomsCollectionCell"
    //    fileprivate var badges = [String]() // Image names of acquired badges
    //    fileprivate var classrooms = [String]() // Image names of participated classrooms
    
    // TODO: Dummy data for icons
    fileprivate var badges = ["badge1", "badge2", "badge3", "badge4", "badge5", "badge6", "badge7", "badge8", "badge9", "badge10", "badge11", "badge12"]
    fileprivate var classrooms = ["biology", "chemistry","computer", "eastasian", "electricengineering", "physics"]
    
    open static let ICON_SIZE: CGFloat = 33.0
    
    fileprivate func collectionViewTemplate() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = true
        return collectionView
    }
    
    fileprivate lazy var badgesCollectionView: UICollectionView = {
        return self.collectionViewTemplate()
    }()
    
    fileprivate lazy var classroomsCollectionView: UICollectionView = {
        return self.collectionViewTemplate()
    }()
    
    fileprivate func sectionLabelTemplate(labelText: String) -> UILabel {
        let label = UILabel()
        label.text = labelText
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }
    
    fileprivate lazy var badgesLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Badges")
    }()
    
    fileprivate lazy var classroomsLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Classrooms")
    }()
    
    fileprivate func setupCollectionViews() {
        self.badgesCollectionView.delegate = self
        self.badgesCollectionView.dataSource = self
        self.classroomsCollectionView.delegate = self
        self.classroomsCollectionView.dataSource = self
        self.badgesCollectionView.register(HorizontalScrollCell.self, forCellWithReuseIdentifier: BADGES_CELL_ID)
        self.classroomsCollectionView.register(HorizontalScrollCell.self, forCellWithReuseIdentifier: CLASSROOMS_CELL_ID)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Each of the two collection views only have one section
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == badgesCollectionView {
            // Return badges collection view
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BADGES_CELL_ID, for: indexPath) as! HorizontalScrollCell
            cell.configureCell(icons: badges)
            return cell
        } else {
            // Return classrooms collection view
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CLASSROOMS_CELL_ID, for: indexPath) as! HorizontalScrollCell
            cell.configureCell(icons: classrooms)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: ProfileController.ICON_SIZE) // Width is defined in HorizontalScrollCell
    }
    
    fileprivate let dividerLineForCollectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    // MARK: Views 3 - Edit Profile and Settings buttons
    
    fileprivate func meBtnTemplate(btnText: String) -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = FONT_HEAVY_MID
        button.titleLabel?.textAlignment = .center
        button.setTitle(btnText, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.darkGray, for: .highlighted)
        button.setBackgroundColor(color: GREEN_UICOLOR, forState: .normal)
        button.setBackgroundColor(color: GRAY_UICOLOR, forState: .highlighted)
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
        log.info("Edit profile")
        // Launch edit profile
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        let controller = EditProfileController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func openSettings() {
        log.info("Open settings")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable top bounce only, and not bottom bounce
        if (scrollView.contentOffset.y <= 0) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    fileprivate func setupViews() {
        // Set up scroll view, and close button on top of scroll view
        let views = setupScrollView()
        let scrollView = views[0] as! UIScrollView
        let containerView = views[1]
        scrollView.delegate = self // Delegate so as to disable top bounce only
        
        // Assign delegate, data source and setup cells for the badges and classrooms colletion views
        self.setupCollectionViews()
        
        // Centered discipline icon and name label
        let disciplineNameAgeContainer = UIView()
        disciplineNameAgeContainer.addSubview(disciplineImageView)
        disciplineNameAgeContainer.addSubview(nameAndAgeLbl)
        disciplineNameAgeContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(disciplineNameAgeContainer)
        containerView.addConstraint(NSLayoutConstraint(item: disciplineNameAgeContainer, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        disciplineNameAgeContainer.addConstraintsWithFormat("H:|[v0(20)]-5-[v1]|", views: disciplineImageView, nameAndAgeLbl)
        disciplineNameAgeContainer.addConstraintsWithFormat("V:|[v0(20)]", views: disciplineImageView)
        disciplineNameAgeContainer.addConstraintsWithFormat("V:|[v0(25)]|", views: nameAndAgeLbl)
        
        // Button container
        let buttonContainer = UIView()
        buttonContainer.addSubview(editProfileBtn)
        buttonContainer.addSubview(settingsBtn)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonContainer)
        let buttonWidth: CGFloat = (UIScreen.main.bounds.width - 6 * 8.0) / 2.0
        buttonContainer.addConstraintsWithFormat("H:|-8-[v0(\(buttonWidth))]", views: editProfileBtn)
        buttonContainer.addConstraintsWithFormat("H:[v0(\(buttonWidth))]-8-|", views: settingsBtn)
        buttonContainer.addConstraintsWithFormat("V:|-[v0(50)]-|", views: editProfileBtn)
        buttonContainer.addConstraintsWithFormat("V:|-[v0(50)]-|", views: settingsBtn)
        
        // Add to subviews
        containerView.addSubview(coverImageView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(badgesLbl)
        containerView.addSubview(badgesCollectionView)
        containerView.addSubview(classroomsLbl)
        containerView.addSubview(classroomsCollectionView)
        containerView.addSubview(dividerLineForCollectionView)
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
        
        // Define main constraints
        let navBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: coverImageView)
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight)-[v0(250)]-14-[v1]-8-[v2(20)]-8-[v3(\(ProfileController.ICON_SIZE))]-8-[v4(20)]-8-[v5(\(ProfileController.ICON_SIZE))]-13-[v6(0.5)]-12-[v7]-\(bottomMargin)-|", views: coverImageView, disciplineNameAgeContainer, badgesLbl, badgesCollectionView, classroomsLbl, classroomsCollectionView, dividerLineForCollectionView, buttonContainer)
        
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: badgesLbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: badgesCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: classroomsLbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: classroomsCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: dividerLineForCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: buttonContainer)
        
        containerView.addConstraintsWithFormat("H:[v0(180)]", views: profileImageView)
        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight + 35)-[v0(180)]", views: profileImageView)
    }
    
}
