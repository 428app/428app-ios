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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "Me"
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        self.loadData()
        self.registerObservers()
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
        // TODO: Badges
        self.classrooms = profileData.classroomIcons
        self.classroomsCollectionView.reloadData()
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
                
                if self.classrooms.count == 0 {
                    self.noClassroomsLbl.isHidden = false
                    self.containerView.addSubview(self.noClassroomsLbl)
                    self.containerView.addConstraint(NSLayoutConstraint(item: self.noClassroomsLbl, attribute: .top, relatedBy: .equal, toItem: self.classroomsLbl, attribute: .bottom, multiplier: 1.0, constant: 8.0))
                    self.containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: self.noClassroomsLbl)
                } else {
                    self.noClassroomsLbl.isHidden = true
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
        imageView.tintColor = RED_UICOLOR
        return imageView
    }()
    
    // MARK: Views 2 - Horizontal collection views of classroom icons
    
    fileprivate let CLASSROOMS_CELL_ID = "classroomsCollectionCell"
    fileprivate var classrooms = [String]()
    
    open static let ICON_SIZE: CGFloat = 33.0

    fileprivate lazy var classroomsCollectionView: UICollectionView = {
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
    
    fileprivate lazy var classroomsLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Classrooms")
    }()
    
    fileprivate func setupCollectionView() {
        self.classroomsCollectionView.delegate = self
        self.classroomsCollectionView.dataSource = self
        self.classroomsCollectionView.register(HorizontalScrollCell.self, forCellWithReuseIdentifier: CLASSROOMS_CELL_ID)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Each of the two collection views only have one section
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Return classrooms collection view
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CLASSROOMS_CELL_ID, for: indexPath) as! HorizontalScrollCell
        cell.configureCell(icons: classrooms)
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
    
    let noClassroomsLbl: UILabel = {
        let label = UILabel()
        label.text = "No classrooms yet."
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
        log.info("Edit profile")
        // Launch EditProfileController which has two sub controllers, EditProfession and EditTagline
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        let controller = EditProfileController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func openSettings() {
        log.info("Open settings")
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
        
        // Assign delegate, data source and setup cells for and classrooms collection view
        self.setupCollectionView()
        
        // Centered discipline icon and name label
        let disciplineNameAgeContainer = UIView()
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
        containerView.addSubview(classroomsLbl)
        containerView.addSubview(classroomsCollectionView)
        containerView.addSubview(editProfileBtn)
        containerView.addSubview(settingsBtn)
        containerView.addSubview(dividerLineForCollectionView)
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
        
        // Define main constraints
        let navBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: coverImageView)
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight)-[v0(220)][v1]-8-[v2(20)]-8-[v3(\(ProfileController.ICON_SIZE))]-13-[v4(0.5)]-12-[v5(50)]-[v6(50)]-\(bottomMargin)-|", views: coverImageView, disciplineNameAgeContainer, classroomsLbl, classroomsCollectionView, dividerLineForCollectionView, editProfileBtn, settingsBtn)
        
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: classroomsLbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: classroomsCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: dividerLineForCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: editProfileBtn)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: settingsBtn)
        
        containerView.addConstraintsWithFormat("H:[v0(180)]", views: profileImageView)
        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight + 35)-[v0(180)]", views: profileImageView)
    }
    
}
