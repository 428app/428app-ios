//
//  SuperlativeController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Social
import Firebase

class SuperlativeController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "superlativeCell"
    
    open var classroom: Classroom!
    fileprivate var superlativeFirebase: (FIRDatabaseReference, FIRDatabaseHandle)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.toggleViews(superlativeType: classroom.superlativeType)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(NOTIF_VOTESELECTED)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: GREEN_UICOLOR), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
        if superlativeFirebase != nil {
            self.superlativeFirebase.0.removeObserver(withHandle: superlativeFirebase.1)
        }
    }
    
    // MARK: Collection view
    
    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = GREEN_UICOLOR
        collectionView.bounces = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SuperlativeCell.self, forCellWithReuseIdentifier: self.CELL_ID)
        return collectionView
    }()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.classroom.superlativeType == SuperlativeType.NOTRATED {
            return self.classroom.superlatives.count
        } else {
            return self.classroom.results.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! SuperlativeCell
        var superlative: Superlative!
        if self.classroom.superlativeType == SuperlativeType.NOTRATED {
            superlative = self.classroom.superlatives[indexPath.item]
        } else {
            superlative = self.classroom.results[indexPath.item]
        }
        cell.configureCell(superlativeObj: superlative)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 168.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.classroom.superlativeType == SuperlativeType.SHARED {
            // Does nothing on click
            return
        }
        let superlative = self.classroom.superlatives[indexPath.item]
        let modalController = ModalVoteController()
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .crossDissolve
        modalController.superlativeName = superlative.superlativeName
        modalController.userVotedFor = superlative.userVotedFor
        modalController.classmates = self.classroom.members
        self.present(modalController, animated: true, completion: nil)
    }
    
    // MARK: Share
    
    fileprivate let didYouKnowLbl: UILabel = {
        let lbl = UILabel()
        lbl.font = FONT_HEAVY_LARGE
        lbl.textColor = GREEN_UICOLOR
        lbl.textAlignment = .center
        lbl.text = "Did you know?"
        return lbl
    }()
    
    fileprivate let didYouKnowText: UITextView = {
        let textView = UITextView()
        textView.showsHorizontalScrollIndicator = false
        textView.font = FONT_MEDIUM_MID
        textView.textColor = UIColor.black
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.tintColor = RED_UICOLOR
        textView.dataDetectorTypes = .all
        return textView
    }()
    
    fileprivate lazy var fbButton: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.setBackgroundColor(color: FB_BLUE_UICOLOR, forState: .normal)
        btn.setBackgroundColor(color: UIColor(red: 50/255.0, green: 75/255.0, blue: 128/255.0, alpha: 1.0), forState: .highlighted) // Darker shade of blue
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitle("Share on Facebook", for: .normal)
        btn.addTarget(self, action: #selector(shareOnFb), for: .touchUpInside)
        btn.layer.cornerRadius = 5.0
        btn.clipsToBounds = true
        return btn
    }()
    
    fileprivate let instructionsIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "info")
        return imageView
    }()
    
    fileprivate let instructionsLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_SMALL
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "Share to unlock superlatives!"
        return label
    }()
    
    func shareOnFb() {
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                socialController.add(#imageLiteral(resourceName: "logo"))
                let url = URL(string: "http://www.428pm.com")
                socialController.add(url)
                self.present(socialController, animated: true, completion: {})
                socialController.completionHandler = { (result:SLComposeViewControllerResult) in
                    if result == SLComposeViewControllerResult.cancelled {
                        // Nothing happen
                        log.info("Sharing got cancelled")
                    } else if result == SLComposeViewControllerResult.done {
                        DataService.ds.shareSuperlative(classroom: self.classroom, completed: { (isSuccess) in
                            if isSuccess {
                                self.toggleViews(superlativeType: SuperlativeType.SHARED)
                            } else {
                                showErrorAlert(vc: self, title: "Error", message: "There was a problem sharing.\nPlease try again.")
                            }
                        })
                    }
                }
            }
        }
    }
    
    fileprivate lazy var shareContainer: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: self.navigationController!.navigationBar.frame.size.height + 15.0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.isUserInteractionEnabled = true
        return view
    }()
    
    fileprivate func setupShareViews() {
        
        let didYouKnowContainer = UIView()
        didYouKnowContainer.addSubview(didYouKnowLbl)
        didYouKnowContainer.addSubview(didYouKnowText)
        didYouKnowContainer.backgroundColor = GRAY_UICOLOR
        didYouKnowContainer.addConstraintsWithFormat("V:|-8-[v0(25)]-8-[v1]-8-|", views: didYouKnowLbl, didYouKnowText)
        didYouKnowContainer.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: didYouKnowLbl)
        didYouKnowContainer.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: didYouKnowText)
        didYouKnowContainer.layer.cornerRadius = 5.0
        
        let instructionsContainer = UIView()
        instructionsContainer.addSubview(instructionsIcon)
        instructionsContainer.addSubview(instructionsLbl)
        instructionsContainer.translatesAutoresizingMaskIntoConstraints = false
        instructionsContainer.addConstraintsWithFormat("H:|[v0(14)]-4-[v1]|", views: instructionsIcon, instructionsLbl)
        instructionsContainer.addConstraintsWithFormat("V:|[v0(14)]", views: instructionsIcon)
        instructionsContainer.addConstraintsWithFormat("V:|-1-[v0(14)]|", views: instructionsLbl)
        shareContainer.addSubview(instructionsContainer)
        shareContainer.addConstraint(NSLayoutConstraint(item: instructionsContainer, attribute: .centerX, relatedBy: .equal, toItem: shareContainer, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        
        shareContainer.addSubview(didYouKnowContainer)
        shareContainer.addSubview(fbButton)
        shareContainer.addSubview(instructionsContainer)
        
        shareContainer.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: didYouKnowContainer)
        shareContainer.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: fbButton)
        shareContainer.addConstraintsWithFormat("V:|-12-[v0(250)]-12-[v1(40)]-8-[v2(40)]", views: didYouKnowContainer, fbButton, instructionsContainer)
        
        view.addSubview(shareContainer)
    }
    
    // MARK: Submit and select superlatives
    
    func checkToEnableSubmitSuperlative() {
        for superlative in self.classroom.superlatives {
            if superlative.userVotedFor == nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                return
            }
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func selectSuperlative(notif: Notification) {
        if let userInfo = notif.userInfo, let superlativeName = userInfo["superlativeName"] as? String, let userVotedFor = userInfo["userVotedFor"] as? Profile {
            for superlative in self.classroom.superlatives {
                if superlative.superlativeName == superlativeName {
                    superlative.userVotedFor = userVotedFor
                    self.collectionView.reloadData()
                }
            }
        }
        checkToEnableSubmitSuperlative()
    }
    
    func submitSuperlatives() { // Used in NOTRATED stage, and on success transfer to RATED stage
        // TODO: Submit superlative to the server here
        DataService.ds.submitSuperlativeVote(classroom: self.classroom) { (isSuccess) in
            if isSuccess {
                self.toggleViews(superlativeType: SuperlativeType.RATED)
            } else {
                showErrorAlert(vc: self, title: "Error", message: "There was a problem submitting your votes.\nPlease try again.")
            }
        }
    }
    
    // MARK: Views
    
    fileprivate func setupViews() {
        self.view.addSubview(self.collectionView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: self.collectionView)
        self.view.addConstraintsWithFormat("V:|[v0]|", views: self.collectionView)
        self.setupShareViews()
    }
    
    fileprivate func toggleViews(superlativeType: SuperlativeType) {
        
        self.classroom.superlativeType = superlativeType
        
        if superlativeType == .RATED {
            // Rated but not shared, hide collection view and show share
            self.navigationItem.title = "Superlatives"
            shareContainer.isHidden = false
            collectionView.isHidden = true
            self.view.backgroundColor = UIColor.white
            self.navigationItem.rightBarButtonItem = nil
            NotificationCenter.default.removeObserver(self, name: NOTIF_VOTESELECTED, object: nil)
            
        } else {
            // Shows collection view
            shareContainer.isHidden = true
            collectionView.isHidden = false
            self.view.backgroundColor = GREEN_UICOLOR
            self.extendedLayoutIncludesOpaqueBars = true
            
            if superlativeType == .NOTRATED {
                // Allow user to rate
                self.navigationItem.title = "Superlatives"
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(submitSuperlatives))
                NotificationCenter.default.addObserver(self, selector: #selector(selectSuperlative), name: NOTIF_VOTESELECTED, object: nil)
                checkToEnableSubmitSuperlative()
            } else {
                // Show results
                self.navigationItem.rightBarButtonItem = nil
                NotificationCenter.default.removeObserver(self, name: NOTIF_VOTESELECTED, object: nil)
            }
            
        }
    }
    // MARK: Firebase
    
    fileprivate func loadData() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        superlativeFirebase = DataService.ds.observeSuperlatives(classroom: classroom) { (isSuccess, updatedClassroom) in
            if isSuccess {
                self.classroom = updatedClassroom
                self.navigationItem.title = self.classroom.isVotingOngoing ? "Running Results" : "Final Results"
                self.collectionView.reloadData()
            } else {
                log.error("[Error] Failed to update superlatives for classroom id: \(self.classroom.cid)")
            }
        }
        
        // TODO: Randomly load a do you know?
        self.didYouKnowText.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        self.didYouKnowText.flashScrollIndicators()
    }

}
