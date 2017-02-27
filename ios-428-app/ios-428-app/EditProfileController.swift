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

class EditProfileController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Edit Profile"
        self.view.backgroundColor = UIColor.white
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadProfileData() // Note that this must come AFTER the viewDidLoad setup above
        self.loadProfilePic()
        NotificationCenter.default.addObserver(self, selector: #selector(loadProfileData), name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadProfilePic), name: NOTIF_MYPROFILEPICDOWNLOADED, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_MYPROFILEPICDOWNLOADED, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.animateEditButton()
    }
    
    // Called upon checking myProfile on viewDidLoad, or upon receiving Notification from SettingsController
    func loadProfileData() {
        
        guard let profile = myProfile else {
            return
        }
        
        // Set profile information
        let ageString = profile.age == nil ? "" : ", \(profile.age!)"
        nameAndAgeLbl.text = "\(profile.name)\(ageString)"
        disciplineImageView.image = UIImage(named: profile.disciplineIcon)
        disciplineText.text = profile.discipline
        schoolText.text = profile.school.isEmpty ? "Ask me why I did not fill this in." : profile.school
        organizationText.text = profile.org.isEmpty ? "Ask me why I did not fill this in." : profile.org
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .left
        let taglineString = NSMutableAttributedString(string: profile.tagline.isEmpty ? "Ask me why I did not fill this in." : profile.tagline, attributes: [NSForegroundColorAttributeName: UIColor.gray, NSParagraphStyleAttributeName: paragraphStyle])
        taglineText.attributedText = taglineString
        
        editProfessionalInfoButton.isEnabled = true
        editTaglineButton.isEnabled = true
    }
    
    func loadProfilePic() {
        
        guard let profilePic = myProfilePhoto else {
            return
        }
        
        profileImageView.image = profilePic
        editPicButton.isEnabled = true
        profileImageView.isUserInteractionEnabled = true
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
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.editProfileImage))
        tap.delegate = self
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    fileprivate lazy var editPicButton: UIButton = {
        let button = UIButton()
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3.0
        button.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        button.setImage(#imageLiteral(resourceName: "edit-with-bg"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(self.editProfileImage), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
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
                self.profilePhotoPicker.sourceType = .camera
                self.present(self.profilePhotoPicker, animated: true, completion: nil)
            }
        }
        let uploadPhotoAction = UIAlertAction(title: "Upload a photo", style: .default) { (action) in
            // Upload a photo
            self.profilePhotoPicker.sourceType = .photoLibrary
            self.present(self.profilePhotoPicker, animated: true, completion: nil)
        }
        let viewPhotoAction = UIAlertAction(title: "View profile photo", style: .default) { (action) in
            if myProfilePhoto == nil {
                showErrorAlert(vc: self, title: "Please upload a profile photo first.", message: "")
            } else {
                // View profile photo
                let pictureModalController = PictureModalController()
                pictureModalController.modalPresentationStyle = .overFullScreen
                pictureModalController.modalTransitionStyle = .crossDissolve
                pictureModalController.picture = self.profileImageView.image
                self.present(pictureModalController, animated: true, completion: nil)
            }
        }
        alertController.addAction(takePhotoAction)
        alertController.addAction(uploadPhotoAction)
        alertController.addAction(viewPhotoAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: {
            alertController.view.tintColor = GREEN_UICOLOR
        })
    }
    
    fileprivate lazy var profilePhotoPicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()
    
    // Delegate function that assigns image, and immediately uploads after picker is dismissed
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if picker == profilePhotoPicker {
            profileImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
            self.uploadImageForImageView(imageView: self.profileImageView)
        }
    }
    
    fileprivate func animateEditButton() {
        UIView.animate(withDuration: 0.2, delay: 0.2, animations: {
            self.editPicButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { (completion) in
            UIView.animate(withDuration: 0.1, animations: {
                self.editPicButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: Firebase storage
    
    fileprivate func showErrorForImageUploadFail() {
        showErrorAlert(vc: self, title: "Failed to save image", message: "We apologize. It doesn't seem like we managed to save your picture. Please check your connection, and try again later.")
    }
    
    // Private function used by sendEditsToServer()
    fileprivate func uploadImageForImageView(imageView: UIImageView) {
        
        guard let image = imageView.image, let testData = UIImageJPEGRepresentation(image, 1.0) else {
            log.error("[Error] Unable to convert image to data")
            self.showErrorForImageUploadFail()
            return
        }
        // Compress image to save storage space, anything more than 2MB will be compressed
        let sizeInBytes = NSData(data: testData).length
        let sizeInMB = CGFloat(sizeInBytes) / (1024.0  * 1024.0)
        let compressionRatio: CGFloat = min(1.0, 2.0/sizeInMB)
        log.info("Uploading with compression ratio: \(compressionRatio)")
        if let data = UIImageJPEGRepresentation(image, compressionRatio) {
            // Save locally first in model before server completes (Before user closes app)
            // Save locally in file path so that when user closes app, we can retry upload when user logs in
            myProfilePhoto = image
            // Cache photo to upload first in case user closes the app at this point
            cachePhotoToUpload(data: data)
            
            StorageService.ss.uploadOwnPic(data: data, completed: { (isSuccess) in
                if !isSuccess {
                    // NOTE: This does not revert back to previous photo. Meaning if the user closes the app and comes back, his photo will be reverted.
                    log.error("[Error] Server unable to save profile pic")
                    self.showErrorForImageUploadFail()
                } else {
                    // Remove cached photo as upload is successful
                    cachePhotoToUpload(data: nil)
                }
            })
        } else {
            log.error("[Error] Profile image unable to be converted to data")
            showErrorForImageUploadFail()
        }
    }
    
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
    
    // MARK: Views 2: Edit Bio, Discipline, School, Organization
    
    fileprivate func editDetailTemplateButton(title: String) -> UIButton {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "edit-3x"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "edit-3x").maskWithColor(color: UIColor.white), for: .highlighted)
        button.setTitle(title, for: .normal)
        button.setTitleColor(GREEN_UICOLOR, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        button.titleLabel?.font = FONT_HEAVY_LARGE
        button.imageEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 6)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
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
    
    func editProfessionalInfo() {
        let controller = EditProfessionalController()
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        navigationController?.pushViewController(controller, animated: true)
    }
    
    fileprivate func sectionLabelTemplate(labelText: String) -> UILabel {
        let label = UILabel()
        label.text = labelText
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }
    
    fileprivate lazy var disciplineLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Discipline")
    }()
    
    fileprivate func fieldTemplate() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }
    
    fileprivate lazy var disciplineText: UILabel = {
        return self.fieldTemplate()
    }()
    
    fileprivate lazy var schoolLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "School")
    }()
    
    fileprivate lazy var schoolText: UILabel = {
        return self.fieldTemplate()
    }()
    
    fileprivate lazy var organizationLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Organization")
    }()
    
    fileprivate lazy var organizationText: UILabel = {
        return self.fieldTemplate()
    }()
    
    fileprivate let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    // MARK: Views 3: Edit tagline, Tagline
    
    fileprivate lazy var editTaglineButton: UIButton = {
        let button = self.editDetailTemplateButton(title: "Edit tagline")
        button.addTarget(self, action: #selector(editTagline), for: .touchUpInside)
        return button
    }()
    
    func editTagline() {
        let controller = EditTaglineController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    fileprivate lazy var taglineLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "What I do at 4:28pm:")
    }()
    
    fileprivate lazy var taglineText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        // Additional options to style font are in attributedText
        label.numberOfLines = 0
        return label
    }()
    
    // Delegate function of scroll view
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Prevents top bounce
        if (scrollView.contentOffset.y <= 0) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    // MARK: Setup views
    
    fileprivate func setupViews() {
        
        // Set up scroll view, and close button on top of scroll view
        let views = setupScrollView()
        let scrollView = views[0] as! UIScrollView
        let containerView = views[1]
        scrollView.delegate = self // Delegate so as to disable top bounce only
        
        // Add to subviews
        
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
        
        containerView.addSubview(coverImageView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(editPicButton)
        containerView.addSubview(editProfessionalInfoButton)
        containerView.addSubview(disciplineLbl)
        containerView.addSubview(disciplineText)
        containerView.addSubview(schoolLbl)
        containerView.addSubview(schoolText)
        containerView.addSubview(organizationLbl)
        containerView.addSubview(organizationText)
        containerView.addSubview(dividerLineView)
        containerView.addSubview(editTaglineButton)
        containerView.addSubview(taglineLbl)
        containerView.addSubview(taglineText)
        
        // Define main constraints
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
        let navBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight)-[v0(250)]-14-[v1(25)]-12-[v2(50)]-8-[v3(20)]-4-[v4(20)]-12-[v5(20)]-4-[v6(20)]-12-[v7(20)]-4-[v8(20)]-12-[v9(0.5)]-16-[v10(50)]-12-[v11(20)]-4-[v12]-\(bottomMargin)-|", views: coverImageView, disciplineNameAgeContainer, editProfessionalInfoButton ,disciplineLbl, disciplineText, schoolLbl, schoolText, organizationLbl, organizationText, dividerLineView, editTaglineButton, taglineLbl, taglineText)
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: coverImageView)
        containerView.addConstraintsWithFormat("H:[v0(180)]", views: profileImageView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: editProfessionalInfoButton)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: disciplineLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: disciplineText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: schoolLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: schoolText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: organizationLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: organizationText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: dividerLineView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: editTaglineButton)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: taglineLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: taglineText)
        
        // Profile image and edit button constraints

        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))
        containerView.addConstraintsWithFormat("V:|-\(navBarHeight + 35)-[v0(180)]", views: profileImageView)
        
        // Align edit button to right and bottom of profile image view
        containerView.addConstraintsWithFormat("V:[v0(40.0)]", views: editPicButton)
        containerView.addConstraintsWithFormat("H:[v0(40.0)]", views: editPicButton)
        containerView.addConstraint(NSLayoutConstraint(item: editPicButton, attribute: .right, relatedBy: .equal, toItem: profileImageView, attribute: .right, multiplier: 1.0, constant: -10.0))
        containerView.addConstraint(NSLayoutConstraint(item: editPicButton, attribute: .bottom, relatedBy: .equal, toItem: profileImageView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
    }
}
