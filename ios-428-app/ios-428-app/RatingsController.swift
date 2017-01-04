//
//  RatingsController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Social

class RatingsController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "ratingCell"
    
    open var ratings: [Rating]!
    open var results: [Rating]!
    open var classmates: [Profile]!
    open var ratingType: RatingType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Ratings"
        self.setupViews()
        self.toggleViews(ratingType: ratingType)
        self.loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(NOTIF_RATINGSELECTED)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: GREEN_UICOLOR), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
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
        collectionView.register(RatingCell.self, forCellWithReuseIdentifier: self.CELL_ID)
        return collectionView
    }()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if ratingType == RatingType.NOTRATED {
            return self.ratings.count
        } else {
            return self.results.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! RatingCell
        var rating: Rating!
        if ratingType == RatingType.NOTRATED {
            rating = self.ratings[indexPath.item]
        } else {
            rating = self.results[indexPath.item]
        }
        cell.configureCell(ratingObj: rating)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 168.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if ratingType == RatingType.SHARED {
            // Does nothing on click
            return
        }
        let rating = self.ratings[indexPath.item]
        let modalController = ModalVoteController()
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .crossDissolve
        modalController.ratingName = rating.ratingName
        modalController.userVotedFor = rating.userVotedFor
        modalController.classmates = self.classmates
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
        label.text = "Share to unlock ratings!"
        return label
    }()
    
    func shareOnFb() {
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                socialController.add(#imageLiteral(resourceName: "logo"))
                let url = URL(string: "http://www.428pm.com")
                socialController.add(url)
                self.present(socialController, animated: true, completion: {
                    log.info("Completed")
                    
                })
                socialController.completionHandler = { (result:SLComposeViewControllerResult) in
                    if result == SLComposeViewControllerResult.cancelled {
                        // Nothing happen
                        log.info("Sharing got cancelled")
                    } else if result == SLComposeViewControllerResult.done {
                        self.toggleViews(ratingType: RatingType.SHARED)
                        log.info("Reveal results")
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
    
    // MARK: Submit and select ratings
    
    func checkToEnableSubmitRating() {
        for rating in ratings {
            if rating.userVotedFor == nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                return
            }
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func selectRating(notif: Notification) {
        if let userInfo = notif.userInfo, let ratingName = userInfo["ratingName"] as? String, let userVotedFor = userInfo["userVotedFor"] as? Profile {
            for rating in self.ratings {
                if rating.ratingName == ratingName {
                    rating.userVotedFor = userVotedFor
                    self.collectionView.reloadData()
                }
            }
        }
        checkToEnableSubmitRating()
    }
    
    func submitRatings() {
        self.toggleViews(ratingType: RatingType.RATED)
    }
    
    // MARK: Views
    
    fileprivate func setupViews() {
        self.view.addSubview(self.collectionView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: self.collectionView)
        self.view.addConstraintsWithFormat("V:|[v0]|", views: self.collectionView)
        self.setupShareViews()
    }
    
    fileprivate func toggleViews(ratingType: RatingType) {
        
        self.ratingType = ratingType
        
        if ratingType == .RATED {
            // Rated but not shared, hide collection view and show share
            self.navigationItem.title = "Ratings"
            shareContainer.isHidden = false
            collectionView.isHidden = true
            self.view.backgroundColor = UIColor.white
            self.navigationItem.rightBarButtonItem = nil
            NotificationCenter.default.removeObserver(self, name: NOTIF_RATINGSELECTED, object: nil)
            
        } else {
            // Shows collection view
            shareContainer.isHidden = true
            collectionView.isHidden = false
            self.view.backgroundColor = GREEN_UICOLOR
            self.extendedLayoutIncludesOpaqueBars = true
            
            if ratingType == .NOTRATED {
                // Allow user to rate
                self.navigationItem.title = "Ratings"
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(submitRatings))
                NotificationCenter.default.addObserver(self, selector: #selector(selectRating), name: NOTIF_RATINGSELECTED, object: nil)
                checkToEnableSubmitRating()
            } else {
                // Show results
                self.navigationItem.title = "Results"
                self.navigationItem.rightBarButtonItem = nil
                NotificationCenter.default.removeObserver(self, name: NOTIF_RATINGSELECTED, object: nil)
            }
            
        }
    }
    // MARK: Firebase
    
    fileprivate func loadData() {
        // TODO: Randomly load a do you know?
        self.didYouKnowText.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        self.didYouKnowText.flashScrollIndicators()
    }

}
