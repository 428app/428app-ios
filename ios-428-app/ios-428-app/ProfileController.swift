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
    
    var connection: Connection!
    
    var profile: Profile!
    
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
//        imageView.layer.masksToBounds = false
//        imageView.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
//        imageView.layer.shadowRadius = 8.0
//        imageView.layer.shadowOpacity = 0.5
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
    
    // MARK: Views 3 - Location, School, Organization Labels
    
    fileprivate lazy var locationLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Location")
    }()
    
    fileprivate func fieldTemplate(text: String) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.font = FONT_MEDIUM_MID
        label.text = text
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }
    
    fileprivate lazy var locationText: UILabel = {
        return self.fieldTemplate(text: "Singapore")
    }()
    
    fileprivate lazy var schoolLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "School")
    }()
    
    fileprivate lazy var schoolText: UILabel = {
        return self.fieldTemplate(text: "Harvard University")
    }()
    
    fileprivate lazy var organizationLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "Organization")
    }()
    
    fileprivate lazy var organizationText: UILabel = {
        return self.fieldTemplate(text: "428")
    }()
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable top bounce only, and not bottom bounce
        if (scrollView.contentOffset.y <= 0) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    fileprivate let dividerLineForProfileInfo: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        return view
    }()
    
    // MARK: Views 4 - What do you do at 4:28pm textview
    
    fileprivate lazy var whatIDoLbl: UILabel = {
        return self.sectionLabelTemplate(labelText: "What I do at 4:28pm:")
    }()
    
    fileprivate lazy var whatIDoText: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_MID
        // Additional options to style font are in attributedText
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate func setupViews() {
        // Set up scroll view, and close button on top of scroll view
        let views = setupScrollView()
        let scrollView = views[0] as! UIScrollView
        let containerView = views[1]
        scrollView.delegate = self // Delegate so as to disable top bounce only
        
        // Assign delegate, data source and setup cells for the badges and classrooms colletion views
        self.setupCollectionViews()
        
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
        disciplineNameAgeContainer.addConstraintsWithFormat("H:|[v0(20)]-5-[v1]|", views: disciplineImageView, nameAndAgeLbl)
        disciplineNameAgeContainer.addConstraintsWithFormat("V:|[v0(20)]", views: disciplineImageView)
        disciplineNameAgeContainer.addConstraintsWithFormat("V:|[v0(25)]|", views: nameAndAgeLbl)
        
        // Add to subviews
        containerView.addSubview(coverImageView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(disciplineNameAgeContainer)
        containerView.addSubview(badgesLbl)
        containerView.addSubview(badgesCollectionView)
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
        containerView.addSubview(whatIDoLbl)
        containerView.addSubview(whatIDoText)
        
        let bottomMargin = CGFloat(self.view.frame.height / 2.5) // Set large bottom margin so user can scroll up and read bottom tagline
        
        // Define main constraints
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: coverImageView)
        containerView.addConstraintsWithFormat("V:|[v0(250)]-14-[v1]-8-[v2(20)]-8-[v3(\(ProfileController.ICON_SIZE))]-8-[v4(20)]-8-[v5(\(ProfileController.ICON_SIZE))]-13-[v6(0.5)]-12-[v7(20)]-4-[v8(20)]-8-[v9(20)]-4-[v10(20)]-8-[v11(20)]-4-[v12(20)]-12-[v13(0.5)]-12-[v14(20)]-4-[v15]-\(bottomMargin)-|", views: coverImageView, disciplineNameAgeContainer, badgesLbl, badgesCollectionView, classroomsLbl, classroomsCollectionView, dividerLineForCollectionView, locationLbl, locationText, schoolLbl, schoolText, organizationLbl, organizationText, dividerLineForProfileInfo, whatIDoLbl, whatIDoText)
        
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: badgesLbl)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: badgesCollectionView)
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
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: whatIDoLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: whatIDoText)
        
        containerView.addConstraintsWithFormat("H:[v0(180)]", views: profileImageView)
        containerView.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0))

        containerView.addConstraintsWithFormat("V:|-35-[v0(180)]", views: profileImageView)
        
        profileImageView.image = #imageLiteral(resourceName: "leo-profile")
        nameAndAgeLbl.text = "Leonard, 25"
        disciplineImageView.image = #imageLiteral(resourceName: "business")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .left
        let whatIDoString = NSMutableAttributedString(string: "My schedule is actually a lot easier to predict than you think. I'm normally hitting the gym at 4:28pm, before I head off to dinner. When I'm not at the gym, I'll go for a swim. When I'm not exercising, I try to keep that time free to catch up on some TechCrunch reading over a hot cup of Peppermint Honey Tea.", attributes: [NSForegroundColorAttributeName: UIColor.gray, NSParagraphStyleAttributeName: paragraphStyle])
        whatIDoText.attributedText = whatIDoString
        
    }
    
    
    
    //    var connection: Connection!
    //
    //    var profile: Profile! {
    //        didSet { // Set from ChatController's openProfile
    //            self.assembleCellData()
    //        }
    //    }
    //
    //    fileprivate let CELL_ID = "profileCell"
    //    fileprivate var heightOfTableViewConstraint: NSLayoutConstraint! // Used to find dynamic height of UITableView
    //    fileprivate var profileCellTitles = ["Organization", "School", "Discipline"]
    //    fileprivate var profileCellContent = ["-", "-", "-"]
    //
    //    override func viewDidLoad() {
    //        super.viewDidLoad()
    //        self.view.backgroundColor = UIColor.white
    //        if profile == nil {
    //            self.downloadProfile()
    //        }
    //        self.setupTableView()
    //        self.setupViews()
    //    }
    //
    //
    //    // MARK: Firebase
    //
    //    fileprivate func downloadProfile() {
    //        DataService.ds.getUserFields(uid: connection.uid) { (isSuccess, downloadedProfile) in
    //            if isSuccess && downloadedProfile != nil {
    //                self.profile = downloadedProfile
    //            }
    //        }
    //    }
    //
    //    fileprivate func assembleCellData() {
    //        self.profileCellContent = [self.profile.org, self.profile.school, self.profile.discipline]
    //        self.tableView.reloadData()
    //        // Download images
    //        log.info("Cover image name: \(self.profile.coverImageName)")
    //
    //        if !profile.coverImageName.isEmpty {
    //            _ = downloadImage(imageUrlString: profile.coverImageName, completed: { (coverImage) in
    //                self.coverImageView.image = coverImage
    //            })
    //        }
    //        _ = downloadImage(imageUrlString: profile.profileImageName, completed: { (profileImage) in
    //            self.profileImageView.image = profileImage
    //        })
    //
    //        nameLbl.text = profile.name
    //        disciplineImageView.image = UIImage(named: profile.disciplineIcon)
    //        ageLocationLbl.text = "\(profile.age), \(profile.location)"
    //
    //        // Taglines
    //
    //        let paragraphStyle = NSMutableParagraphStyle()
    //        paragraphStyle.lineSpacing = 6
    //        let tagstr1 = NSMutableAttributedString(string: "I am working on", attributes: [NSForegroundColorAttributeName: GREEN_UICOLOR, NSFontAttributeName: FONT_HEAVY_MID, NSParagraphStyleAttributeName: paragraphStyle])
    //        let tag1 = profile.tagline1.isEmpty ? "..." : profile.tagline1
    //        let tagline1 = NSMutableAttributedString(string: " " + tag1, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
    //        tagstr1.append(tagline1)
    //        tagline1Lbl.attributedText = tagstr1
    //
    //        let tagstr2 = NSMutableAttributedString(string: "I want to eventually", attributes: [NSForegroundColorAttributeName: GREEN_UICOLOR, NSFontAttributeName: FONT_HEAVY_MID, NSParagraphStyleAttributeName: paragraphStyle])
    //        let tag2 = profile.tagline2.isEmpty ? "..." : profile.tagline2
    //        let tagline2 = NSMutableAttributedString(string: " " + tag2, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
    //        tagstr2.append(tagline2)
    //        tagline2Lbl.attributedText = tagstr2
    //    }
    //
    //
    //
    //
    //
    //    fileprivate let ageLocationLbl: UILabel = {
    //       let label = UILabel()
    //        label.textAlignment = .center
    //        label.font = FONT_MEDIUM_MID
    //        label.textColor = UIColor.darkGray
    //        return label
    //    }()
    //
    //    fileprivate let topDividerLineView: UIView = {
    //        let view = UIView()
    //        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
    //        return view
    //    }()
    //
    //    fileprivate let tableView: UITableView = {
    //        let tableView = UITableView()
    //        tableView.backgroundColor = UIColor.white
    //        tableView.showsHorizontalScrollIndicator = false
    //        tableView.showsVerticalScrollIndicator = false
    //        tableView.bounces = false
    //        tableView.isScrollEnabled = false
    //        return tableView
    //    }()
    //
    //    fileprivate let bottomDividerLineView: UIView = {
    //        let view = UIView()
    //        view.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
    //        return view
    //    }()
    //
    //    fileprivate let tagline1Lbl: UILabel = {
    //       let label = UILabel()
    //        label.numberOfLines = 0
    //        label.font = FONT_MEDIUM_MID
    //        label.textColor = UIColor.darkGray
    //        label.textAlignment = .left
    //        return label
    //    }()
    //
    //    fileprivate let tagline2Lbl: UILabel = {
    //        let label = UILabel()
    //        label.numberOfLines = 0
    //        label.font = FONT_MEDIUM_MID
    //        label.textColor = UIColor.darkGray
    //        label.textAlignment = .left
    //        return label
    //    }()
    //
    //    fileprivate func setupTableView() {
    //        tableView.delegate = self
    //        tableView.dataSource = self
    //        tableView.register(ProfileCell.self, forCellReuseIdentifier: CELL_ID)
    //        tableView.separatorStyle = .none
    //        tableView.allowsSelection = false
    //        tableView.estimatedRowHeight = 50.0
    //        tableView.rowHeight = UITableViewAutomaticDimension
    //    }
    //
    //
    //
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
    
    //    // MARK: Table view
    //
    //    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return UITableViewAutomaticDimension
    //    }
    //    
    //    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return UITableViewAutomaticDimension
    //    }
    //    
    //    func numberOfSections(in tableView: UITableView) -> Int {
    //        return 1
    //    }
    //    
    //    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //        return profileCellTitles.count
    //    }
    //    
    //    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! ProfileCell
    //        let cellTitle = self.profileCellTitles[indexPath.row]
    //        let cellContent = self.profileCellContent[indexPath.row]
    //        cell.configureCell(title: cellTitle, content: cellContent)
    //        return cell
    //    }
}
