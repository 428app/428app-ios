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

class EditProfileController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    fileprivate let CELL_ID = "editProfileCell"
    fileprivate var heightOfTableViewConstraint: NSLayoutConstraint! // Used to find dynamic height of UITableView
    fileprivate var profileCellTitles = [String]()
    fileprivate var profileCellContent = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Edit Profile"
        self.navigationItem.rightBarButtonItem = saveButton
        self.view.backgroundColor = UIColor.white
        self.setupViews()
        self.setupTableView()
        self.loadProfileData() // Note that this must come AFTER the above setup
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadProfileData), name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.animateEditButtons()
    }
    
    // Called upon checking myProfile on viewDidLoad, or upon receiving Notification from SettingsController
    func loadProfileData() {
        guard let profile = myProfile else {
            return
        }
        
        // Basic info on top
        nameLbl.text = profile.name
        disciplineImageView.image = UIImage(named: profile.disciplineIcon)
        ageLocationLbl.text = "\(profile.age), \(profile.location)"
        if let coverImage = myCoverPhoto {
            coverImageView.image = coverImage
            coverImageView.isUserInteractionEnabled = true
            editCoverImageButton.isEnabled = true
        }
        if let profileImage = myProfilePhoto {
            profileImageView.image = profileImage
            profileImageView.isUserInteractionEnabled = true
            editProfileImageButton.isEnabled = true
        }
        
        // Professional info in the order: Organization, School, Discipline
        self.profileCellContent = [profile.org, profile.school, profile.discipline]
        self.tableView.reloadData()
        
        // Tags
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let tagstr1 = NSMutableAttributedString(string: "I am working on", attributes: [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: FONT_HEAVY_MID, NSParagraphStyleAttributeName: paragraphStyle])
        let tag1 = profile.tagline1 == "" ? "..." : profile.tagline1
        let tagline1 = NSMutableAttributedString(string: " " + tag1, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        tagstr1.append(tagline1)
        tagline1Lbl.attributedText = tagstr1

        let tagstr2 = NSMutableAttributedString(string: "I want to eventually", attributes: [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: FONT_HEAVY_MID, NSParagraphStyleAttributeName: paragraphStyle])
        let tag2 = profile.tagline2 == "" ? "..." : profile.tagline2
        let tagline2 = NSMutableAttributedString(string: " " + tag2, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        tagstr2.append(tagline2)
        tagline2Lbl.attributedText = tagstr2
        
        editProfessionalInfoButton.isEnabled = true
        editTaglineButton.isEnabled = true
    }
    
    // MARK: Profile views
    
    fileprivate lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(color: GRAY_UICOLOR)
        imageView.autoresizesSubviews = true
        imageView.clipsToBounds = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(editProfileBg))
        tapGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    fileprivate lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(color: GRAY_UICOLOR)
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 1.5
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.75
        imageView.layer.shadowRadius = 3.0
        imageView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(editProfileImage))
        tapGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
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
        imageView.image = UIImage(color: GRAY_UICOLOR)
        imageView.tintColor = UIColor.lightGray
        return imageView
    }()
    
    fileprivate let ageLocationLbl: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.black
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
        label.textColor = UIColor.lightGray
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let tagline2Lbl: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.lightGray
        label.textAlignment = .left
        return label
    }()
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable top bounce only, and not bottom bounce
        if (scrollView.contentOffset.y <= 0) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    // MARK: Edit views
    
    fileprivate lazy var saveButton: UIBarButtonItem = {
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(sendEditsToServer))
        saveButton.isEnabled = false
        return saveButton
    }()
    
    func sendEditsToServer() {
        // After getting response, make saveButton disabled again
        saveButton.isEnabled = false
    }
    
    // MARK: Edit photos
    
    fileprivate func editImageTemplateButton() -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = FONT_MEDIUM_SMALL
        button.setImage(#imageLiteral(resourceName: "camera"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: -4, left: 0, bottom: 0, right: 5)
        button.titleEdgeInsets = UIEdgeInsets(top: -3.5, left: 5, bottom: 0, right: 0)
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("Edit", for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        button.layer.cornerRadius = 6.0
        button.clipsToBounds = true
        button.isEnabled = false
        return button
    }
    
    fileprivate lazy var editProfileImageButton: UIButton = {
        let button = self.editImageTemplateButton()
        button.addTarget(self, action: #selector(editProfileImage), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var editCoverImageButton: UIButton = {
        let button = self.editImageTemplateButton()
        button.addTarget(self, action: #selector(editProfileBg), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var picPicker: UIImagePickerController = {
       let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()
    
    fileprivate lazy var bgPicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()

    // Delegate function that assigns image after picked
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        saveButton.isEnabled = true
        if picker == picPicker {
            profileImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        } else {
            coverImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
    }
    
    func editProfileImage() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tintColor = GREEN_UICOLOR
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take a new photo", style: .default) { (action) in
            // Take a new photo
            if UIImagePickerController.availableCaptureModes(for: .rear) == nil {
               // No camera
                showErrorAlert(vc: self, title: "No camera", message: "Your device does not have a camera")
            } else {
                self.picPicker.sourceType = .camera
                self.present(self.picPicker, animated: true, completion: nil)
            }
        }
        let uploadPhotoAction = UIAlertAction(title: "Upload a photo", style: .default) { (action) in
            // Upload a photo
            self.picPicker.sourceType = .photoLibrary
            self.present(self.picPicker, animated: true, completion: nil)
        }
        let viewPhotoAction = UIAlertAction(title: "View profile photo", style: .default) { (action) in
            // View profile photo
            let pictureModalController = PictureModalController()
            pictureModalController.modalPresentationStyle = .overFullScreen
            pictureModalController.modalTransitionStyle = .crossDissolve
            pictureModalController.picture = self.profileImageView.image
            self.present(pictureModalController, animated: true, completion: nil)
        }
        alertController.addAction(takePhotoAction)
        alertController.addAction(uploadPhotoAction)
        alertController.addAction(viewPhotoAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func editProfileBg() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tintColor = GREEN_UICOLOR
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take a new photo", style: .default) { (action) in
            // Take a new photo
            self.bgPicker.sourceType = .camera
            self.present(self.bgPicker, animated: true, completion: nil)
        }
        let uploadPhotoAction = UIAlertAction(title: "Upload a photo", style: .default) { (action) in
            // Upload a photo
            self.bgPicker.sourceType = .photoLibrary
            self.present(self.bgPicker, animated: true, completion: nil)
        }
        let viewPhotoAction = UIAlertAction(title: "View cover photo", style: .default) { (action) in
            // View cover photo
            let pictureModalController = PictureModalController()
            pictureModalController.modalPresentationStyle = .overFullScreen
            pictureModalController.modalTransitionStyle = .crossDissolve
            pictureModalController.picture = self.coverImageView.image
            self.present(pictureModalController, animated: true, completion: nil)
        }
        alertController.addAction(takePhotoAction)
        alertController.addAction(uploadPhotoAction)
        alertController.addAction(viewPhotoAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Edit text
    
    fileprivate func editDetailTemplateButton(title: String) -> UIButton {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "edit"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "edit").maskWithColor(color: UIColor.white), for: .highlighted)
        button.setTitle(title, for: .normal)
        button.setTitleColor(GREEN_UICOLOR, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        button.titleLabel?.font = FONT_MEDIUM_SMALLMID
        button.imageEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 4)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.borderColor = GREEN_UICOLOR.cgColor
        button.layer.borderWidth = 0.8
        button.layer.cornerRadius = 4.0
        button.clipsToBounds = true
        button.setBackgroundColor(color: UIColor.white, forState: .normal)
        button.setBackgroundColor(color: GREEN_UICOLOR, forState: .highlighted)
        button.isEnabled = false
        return button
    }
    
    fileprivate lazy var editProfessionalInfoButton: UIButton = {
        let button = self.editDetailTemplateButton(title: "Edit professional info")
        button.addTarget(self, action: #selector(editProfessionalInfo), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var editTaglineButton: UIButton = {
        let button = self.editDetailTemplateButton(title: "Edit tagline")
        button.addTarget(self, action: #selector(editTagline), for: .touchUpInside)
        return button
    }()
    
    func editProfessionalInfo() {
        let controller = EditProfessionalController()
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func editTagline() {
        let controller = EditTaglineController()
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        navigationController?.pushViewController(controller, animated: true)
    }
    
    fileprivate func animateEditButtons() {
        // Called in viewDidAppear to animate the edit buttons to signal to the user that they can click on these
        UIView.animate(withDuration: 0.2, delay: 0.2, animations: {
            self.editCoverImageButton.imageView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.editProfileImageButton.imageView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { (completion) in
                UIView.animate(withDuration: 0.15, animations: { 
                    self.editCoverImageButton.imageView?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    self.editProfileImageButton.imageView?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                })
        }
    }
    
    fileprivate func setupViews() {
        // Set up scroll view, and close button on top of scroll view
        let views = setupScrollView()
        let scrollView = views[0] as! UIScrollView
        let containerView = views[1]
        scrollView.delegate = self // Delegate so as to disable top bounce only
        
        // Add to subviews
        containerView.addSubview(coverImageView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(editProfileImageButton)
        containerView.addSubview(editCoverImageButton)
        
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
        containerView.addSubview(editProfessionalInfoButton)
        containerView.addSubview(tableView)
        containerView.addSubview(bottomDividerLineView)
        containerView.addSubview(editTaglineButton)
        containerView.addSubview(tagline1Lbl)
        containerView.addSubview(tagline2Lbl)
        
        // Define constraints
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: coverImageView)
        containerView.addConstraintsWithFormat("V:|[v0(250)]", views: coverImageView)
        containerView.addConstraint(NSLayoutConstraint(item: editCoverImageButton, attribute: .bottom, relatedBy: .equal, toItem: coverImageView, attribute: .bottom, multiplier: 1.0, constant: 4.0))
        containerView.addConstraint(NSLayoutConstraint(item: editCoverImageButton, attribute: .right, relatedBy: .equal, toItem: coverImageView, attribute: .right, multiplier: 1.0, constant: 4.0))
        containerView.addConstraintsWithFormat("H:[v0(80)]", views: editCoverImageButton)
        containerView.addConstraintsWithFormat("V:[v0(35)]", views: editCoverImageButton)
        
        containerView.addConstraintsWithFormat("H:[v0(150)]", views: profileImageView)
        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: editProfileImageButton, attribute: .bottom, relatedBy: .equal, toItem: profileImageView, attribute: .bottom, multiplier: 1.0, constant: 4.0))
        containerView.addConstraint(NSLayoutConstraint(item: editProfileImageButton, attribute: .right, relatedBy: .equal, toItem: profileImageView, attribute: .right, multiplier: 1.0, constant: 4.0))
        containerView.addConstraintsWithFormat("H:[v0(80)]", views: editProfileImageButton)
        containerView.addConstraintsWithFormat("V:[v0(35)]", views: editProfileImageButton)
        
        
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: ageLocationLbl)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: editProfessionalInfoButton)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: editTaglineButton)
        
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: topDividerLineView)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: bottomDividerLineView)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: tagline1Lbl)
        containerView.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: tagline2Lbl)
        
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
        
        heightOfTableViewConstraint = NSLayoutConstraint(item: self.tableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1000)
        containerView.addConstraint(heightOfTableViewConstraint)
        containerView.addConstraintsWithFormat("V:|-175-[v0(150)]-10-[v1]-6-[v2(20)]-8-[v3(0.5)]-10-[v4(40)]-5-[v5]-2-[v6(0.5)]-12-[v7(40)]-10-[v8]-20-[v9]-\(bottomMargin)-|", views: self.profileImageView, nameDisciplineContainer, self.ageLocationLbl, self.topDividerLineView, self.editProfessionalInfoButton, self.tableView, self.bottomDividerLineView, self.editTaglineButton, self.tagline1Lbl, self.tagline2Lbl)
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
        self.profileCellContent = ["-", "-", "-"]
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
        cell.configureCell(title: cellTitle, content: cellContent, isEdit: true)
        return cell
    }
}
