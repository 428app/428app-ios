//
//  ProfileController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/16/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit


class ProfileController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    open var profile: Profile!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(openProfileIconModal), name: NOTIF_PROFILEICONTAPPED, object: nil)
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
        NotificationCenter.default.removeObserver(self, name: NOTIF_PROFILEICONTAPPED, object: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Views 0 - Close button, Profile image, cover image
    
    fileprivate lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizesSubviews = true
        imageView.clipsToBounds = true
        imageView.image = UIImage(color: GREEN_UICOLOR)
        imageView.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(coverImageDrag(sender:)))
        imageView.addGestureRecognizer(pan)
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
        imageView.image = #imageLiteral(resourceName: "downbg").alpha(value: 0.55)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    fileprivate lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 4.0
        imageView.layer.cornerRadius = 90.0 // Actual image size is 180.0 so this is /2
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
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
    
    // MARK: Views 1 - Discipline icon, name and age label, and message button
    
    fileprivate let nameAndAgeLbl: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.darkGray
        return label
    }()
    
    fileprivate let disciplineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = GREEN_UICOLOR
        return imageView
    }()
    
    fileprivate lazy var messageBtn: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "message-U"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "message-F"), for: .highlighted)
        button.setTitle("Send message", for: .normal)
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
        button.addTarget(self, action: #selector(messageUser), for: .touchUpInside)
        return button
    }()
    
    func messageUser() {
        // Fetch this user's inbox from server
        DataService.ds.getInbox(profile2: profile!) { (isSuccess, inbox) in
            // NOTE: The steps to get to the chat page are a bit complicated but essentially this happens:
            // 1) Post notification to the controller that called this modal
            // 2) That controller switches the tab to Inbox and sets the global side effect inboxToOpen
            // 3) InboxController reads inboxToOpen and opens the Inbox, then clears the side effect inboxToOpen
            self.dismiss(animated: true, completion: {
                NotificationCenter.default.post(name: NOTIF_SENDMESSAGE, object: nil, userInfo: ["inbox": inbox])
            })
        }
    }
    
    // MARK: Views 2 - Horizontal collection views of classroom icons
    
    fileprivate let CLASSROOMS_CELL_ID = "classroomsCollectionCell"
    fileprivate var classrooms = [String]() // Image names of participated classrooms

    open static let ICON_SIZE: CGFloat = 43.0
    
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
    
    // Empty view
    
    let noClassroomsLbl: UILabel = {
        let label = UILabel()
        label.text = "No classrooms yet."
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.gray
        label.textAlignment = .left
        return label
    }()
    
    // MARK: Views 3 - Location, School, Organization Labels
    
    fileprivate lazy var locationLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Location")
    }()
    
    fileprivate func fieldTemplate() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.font = FONT_MEDIUM_MID
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }
    
    fileprivate lazy var locationText: UILabel = {
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
    
    fileprivate let dividerLineForProfileInfo: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    // MARK: Views 4 - Tagline
    
    fileprivate lazy var taglineLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "What I do at 4:28pm:")
    }()
    
    fileprivate lazy var taglineText: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_MID
        // Additional options to style font are in attributedText
        label.numberOfLines = 0
        return label
    }()
    
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
        
        // Assign delegate, data source and setup cells for classrooms collection view
        self.setupCollectionView()
        
        // Add close button on top of scroll view
        view.addSubview(closeButtonBg)
        view.addSubview(closeButton)
        view.addConstraintsWithFormat("H:|-15-[v0(30)]", views: closeButtonBg)
        view.addConstraintsWithFormat("V:|-25-[v0(30)]", views: closeButtonBg)
        view.addConstraintsWithFormat("H:|-10-[v0(40)]", views: closeButton)
        view.addConstraintsWithFormat("V:|-20-[v0(40)]", views: closeButton)
        closeButton.addTarget(self, action: #selector(closeProfile), for: .touchUpInside)
        
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
        containerView.addSubview(messageBtn)
        containerView.addSubview(classroomsLbl)
        containerView.addSubview(classroomsCollectionView)
        containerView.addSubview(dividerLineForCollectionView)
        containerView.addSubview(locationLbl)
        containerView.addSubview(locationText)
        containerView.addSubview(schoolLbl)
        containerView.addSubview(schoolText)
        containerView.addSubview(organizationLbl)
        containerView.addSubview(organizationText)
        containerView.addSubview(dividerLineForProfileInfo)
        containerView.addSubview(taglineLbl)
        containerView.addSubview(taglineText)
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.25) // Set large bottom margin so user can scroll up and read bottom tagline
        
        // Define main constraints
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: coverImageView)
        containerView.addConstraintsWithFormat("V:|[v0(250)]-14-[v1]-8-[v2(50)]-8-[v3(20)]-8-[v4(\(ProfileController.ICON_SIZE))]-13-[v5(0.5)]-12-[v6(20)]-4-[v7(20)]-12-[v8(20)]-4-[v9(20)]-12-[v10(20)]-4-[v11(20)]-16-[v12(0.5)]-16-[v13(20)]-4-[v14]-\(bottomMargin)-|", views: coverImageView, disciplineNameAgeContainer, messageBtn, classroomsLbl, classroomsCollectionView, dividerLineForCollectionView, locationLbl, locationText, schoolLbl, schoolText, organizationLbl, organizationText, dividerLineForProfileInfo, taglineLbl, taglineText)
        
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: messageBtn)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: classroomsLbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: classroomsCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: dividerLineForCollectionView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: locationLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: locationText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: schoolLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: schoolText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: organizationLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: organizationText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: dividerLineForProfileInfo)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: taglineLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: taglineText)
        
        // Profile image view over cover image
        containerView.addConstraintsWithFormat("H:[v0(180)]", views: profileImageView)
        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))

        containerView.addConstraintsWithFormat("V:|-35-[v0(180)]", views: profileImageView)
        
        loadData()
        
        // Add no classrooms lbl to collection views in case there are no classrooms
        // Note that this has to be after data is loaded above
        if classrooms.count == 0 {
            self.noClassroomsLbl.isHidden = false
            containerView.addSubview(noClassroomsLbl)
            containerView.addConstraint(NSLayoutConstraint(item: noClassroomsLbl, attribute: .top, relatedBy: .equal, toItem: classroomsLbl, attribute: .bottom, multiplier: 1.0, constant: 8.0))
            containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: noClassroomsLbl)
        } else {
            self.noClassroomsLbl.isHidden = true
        }
    }
    
    fileprivate func loadData() {
        _ = downloadImage(imageUrlString: profile.profileImageName, completed: { image in
            self.profileImageView.image = image
        })
        nameAndAgeLbl.text = "\(profile.name), \(profile.age)"
        disciplineImageView.image = UIImage(named: profile.disciplineIcon)
        
        locationText.text = profile.location.isEmpty ? "Unknown" : profile.location
        schoolText.text = profile.school.isEmpty ? "TOO LAZY to fill this in." : profile.school
        organizationText.text = profile.org.isEmpty ? "TOO LAZY to fill this in." : profile.org
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .left
        let taglineString = NSMutableAttributedString(string: profile.tagline.isEmpty ? "TOO LAZY to fill this in." : profile.tagline, attributes: [NSForegroundColorAttributeName: UIColor.gray, NSParagraphStyleAttributeName: paragraphStyle])
        taglineText.attributedText = taglineString
        
        self.classrooms = profile.classroomIcons
        self.classroomsCollectionView.reloadData()
    }
    
    // MARK: Close profile
    
    func closeProfile(button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Interactor to dismiss modal by dragging cover photo down
    var interactor: Interactor? = nil
    func coverImageDrag(sender: UIPanGestureRecognizer) {
        let percentThreshold: CGFloat = 0.3
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        self.view.transform = CGAffineTransform(translationX: 0.0, y: progress * UIScreen.main.bounds.height)
        guard let interactor = interactor else { return }
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            if progress > percentThreshold {
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.transform = CGAffineTransform(translationX: 0.0, y: 0.0)
                })
            }
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finish()
                : interactor.cancel()
        default:
            break
        }
    }
}
