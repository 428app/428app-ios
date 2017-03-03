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

class SuperlativeController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIWebViewDelegate {
    
    fileprivate let CELL_ID = "superlativeCell"
    
    open var playgroup: Playgroup!
    fileprivate var superlativeFirebase: (FIRDatabaseReference, FIRDatabaseHandle)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.toggleViews(superlativeType: self.playgroup.superlativeType)
        self.loadData()
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil { // Leaving
            NotificationCenter.default.removeObserver(NOTIF_VOTESELECTED)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let color = playgroup.superlativeType == .SHARED ? RED_UICOLOR : GREEN_UICOLOR
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: color), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
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
        collectionView.backgroundColor = self.playgroup.superlativeType == .SHARED ? RED_UICOLOR : GREEN_UICOLOR
        collectionView.bounces = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SuperlativeCell.self, forCellWithReuseIdentifier: self.CELL_ID)
        return collectionView
    }()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.playgroup.superlativeType == SuperlativeType.NOTVOTED {
            return self.playgroup.superlatives.count
        } else {
            return self.playgroup.results.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! SuperlativeCell
        var superlative: Superlative!
        if self.playgroup.superlativeType == SuperlativeType.NOTVOTED {
            superlative = self.playgroup.superlatives[indexPath.item]
        } else {
            superlative = self.playgroup.results[indexPath.item]
        }
        cell.configureCell(superlativeObj: superlative)
    
        // Green background for not voted, Red background for results
        if self.playgroup.superlativeType == SuperlativeType.NOTVOTED {
            cell.setColorOfViews(color: GREEN_UICOLOR)
        } else if self.playgroup.superlativeType == SuperlativeType.SHARED {
            cell.setColorOfViews(color: RED_UICOLOR)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 168.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.playgroup.superlativeType == SuperlativeType.SHARED {
            // Does nothing on click
            return
        }
        let superlative = self.playgroup.superlatives[indexPath.item]
        let modalController = ModalVoteController()
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .crossDissolve
        modalController.superlativeName = superlative.superlativeName
        modalController.userVotedFor = superlative.userVotedFor
        modalController.playpeers = self.playgroup.members
        self.present(modalController, animated: true, completion: nil)
    }
    
    // MARK: Share
    
    fileprivate let didYouKnowLbl: UILabel = {
        let lbl = UILabel()
        lbl.font = FONT_HEAVY_XLARGE
        lbl.textColor = GREEN_UICOLOR
        lbl.textAlignment = .center
        lbl.text = "Did you know?"
        return lbl
    }()
    
    fileprivate lazy var didYouKnowVideo: UIWebView = {
        let webView = UIWebView()
        webView.delegate = self
        webView.allowsInlineMediaPlayback = true
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        return webView
    }()
    
    fileprivate lazy var placeHolderVideo: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    fileprivate lazy var activityIndicator: CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading")!.maskWithColor(color: GREEN_UICOLOR)!
        let activityIndicatorView = CustomActivityIndicatorView(image: image)
        activityIndicatorView.isHidden = true
        return activityIndicatorView
    }()
    
    // MARK: Web view delegates for Share
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        placeHolderVideo.isHidden = true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        // Padding to remove the ugly default left padding of UIWebViews
        let negativePadding = "document.body.style.margin='0';document.body.style.padding = '0'"
        didYouKnowVideo.stringByEvaluatingJavaScript(from: negativePadding)
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        placeHolderVideo.isHidden = false
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        log.info("Fail to load with error: \(error)")
        activityIndicator.stopAnimating()
    }

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
        label.text = "Share to unlock results!"
        return label
    }()
    
    fileprivate var shareLink = ""
    
    func shareOnFb() {
        log.info("SHARE ON FB")
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                let url = URL(string: shareLink)
                // Just share the video, do not share anything 428 related, and hope people type 428 in the post
                socialController.add(url)
                self.present(socialController, animated: true, completion: {})
                socialController.completionHandler = { (result:SLComposeViewControllerResult) in
                    if result == SLComposeViewControllerResult.cancelled {
                        // Nothing happen
                        log.info("Sharing got cancelled")
                    } else if result == SLComposeViewControllerResult.done {
                        showLoader(message: "Retrieving superlative results")
                        DataService.ds.shareSuperlative(playgroup: self.playgroup, completed: { (isSuccess) in
                            hideLoader()
                            if isSuccess {
                                self.toggleViews(superlativeType: SuperlativeType.SHARED)
                                self.navigationItem.title = self.playgroup.isVotingOngoing ? "Running Results" : "Final Results"
                                // Hack: Adjust the screen
                                self.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
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
        let shareView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height * 0.2, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.65))
        shareView.isUserInteractionEnabled = true
        return shareView
    }()
    
    fileprivate func setupShareViews() {
        
        let didYouKnowContainer = UIView()
        didYouKnowContainer.addSubview(didYouKnowLbl)
        didYouKnowContainer.addSubview(didYouKnowVideo)
        didYouKnowContainer.addConstraintsWithFormat("V:|-8-[v0(25)]-8-[v1(250)]-8-|", views: didYouKnowLbl, didYouKnowVideo)
        didYouKnowContainer.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: didYouKnowLbl)
        didYouKnowContainer.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: didYouKnowVideo)
        didYouKnowContainer.layer.cornerRadius = 5.0
        
        didYouKnowVideo.addSubview(placeHolderVideo)
        didYouKnowVideo.addConstraintsWithFormat("H:|[v0]|", views: placeHolderVideo)
        didYouKnowVideo.addConstraintsWithFormat("V:|[v0]|", views: placeHolderVideo)
        
        didYouKnowVideo.addSubview(activityIndicator)
        let topMargin = (250/2.0) - activityIndicator.frame.height/2.0 - 4.0
        didYouKnowVideo.addConstraintsWithFormat("V:|-\(topMargin)-[v0]", views: activityIndicator)
        let leftMargin = (UIScreen.main.bounds.width - 8.0*4)/2.0 - activityIndicator.frame.width/2.0 - 8.0
        didYouKnowVideo.addConstraintsWithFormat("H:|-\(leftMargin)-[v0]", views: activityIndicator)
        
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
        shareContainer.addConstraintsWithFormat("H:|-18-[v0]-18-|", views: fbButton)
        shareContainer.addConstraintsWithFormat("V:|-12-[v0]-12-[v1(40)]-8-[v2(40)]", views: didYouKnowContainer, fbButton, instructionsContainer)
        
        view.addSubview(shareContainer)
    }
    
    // MARK: Submit and select superlatives
    
    func checkToEnableSubmitSuperlative() {
        for superlative in self.playgroup.superlatives {
            if superlative.userVotedFor == nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                return
            }
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func selectSuperlative(notif: Notification) {
        if let userInfo = notif.userInfo, let superlativeName = userInfo["superlativeName"] as? String, let userVotedFor = userInfo["userVotedFor"] as? Profile {
            for superlative in self.playgroup.superlatives {
                if superlative.superlativeName == superlativeName {
                    superlative.userVotedFor = userVotedFor
                    self.collectionView.reloadData()
                }
            }
        }
        checkToEnableSubmitSuperlative()
    }
    
    func submitSuperlatives() { // Used in NOTVOTED stage, and on success transfer to VOTED stage
        showLoader(message: "Submitting your votes...")
        DataService.ds.submitSuperlativeVote(playgroup: self.playgroup) { (isSuccess) in
            hideLoader()
            if isSuccess {
                self.toggleViews(superlativeType: SuperlativeType.VOTED)
            } else {
                showErrorAlert(vc: self, title: "Error", message: "There was a problem submitting your votes.\nPlease try again.")
            }
        }
    }
    
    // MARK: Views
    
    var topConstraintForCollectionView: NSLayoutConstraint!
    fileprivate func setupViews() {
        self.view.addSubview(self.collectionView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: self.collectionView)
        topConstraintForCollectionView = NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(topConstraintForCollectionView)
        self.view.addConstraintsWithFormat("V:[v0]|", views: self.collectionView)
        self.setupShareViews()
    }
    
    fileprivate func toggleViews(superlativeType: SuperlativeType) {
        
        self.playgroup.superlativeType = superlativeType
        
        if superlativeType == .VOTED {
            // Rated but not shared, hide collection view and show share
            self.navigationItem.title = "Superlatives"
            self.extendedLayoutIncludesOpaqueBars = true
            shareContainer.isHidden = false
            collectionView.isHidden = true
            self.view.backgroundColor = GRAY_UICOLOR
            self.navigationItem.rightBarButtonItem = nil
            NotificationCenter.default.removeObserver(self, name: NOTIF_VOTESELECTED, object: nil)
            
        } else {
            // Shows collection view
            shareContainer.isHidden = true
            collectionView.isHidden = false
            self.extendedLayoutIncludesOpaqueBars = true
            
            if superlativeType == .NOTVOTED {
                // Allow user to rate
                self.navigationItem.title = "Superlatives"
                collectionView.backgroundColor = GREEN_UICOLOR
                self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: GREEN_UICOLOR), for: .default)
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(submitSuperlatives))
                NotificationCenter.default.addObserver(self, selector: #selector(selectSuperlative), name: NOTIF_VOTESELECTED, object: nil)
                checkToEnableSubmitSuperlative()
            } else {
                // Show results
                collectionView.backgroundColor = RED_UICOLOR
                self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: RED_UICOLOR), for: .default)
                self.navigationItem.rightBarButtonItem = nil
                NotificationCenter.default.removeObserver(self, name: NOTIF_VOTESELECTED, object: nil)
            }
            self.collectionView.reloadData()
        }
    }
    // MARK: Firebase
    
    fileprivate func loadData() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        superlativeFirebase = DataService.ds.observeSuperlatives(playgroup: playgroup) { (isSuccess, updatedPlaygroup) in
            if isSuccess {
                self.playgroup = updatedPlaygroup
                if self.playgroup.superlativeType == .SHARED {
                    self.navigationItem.title = self.playgroup.isVotingOngoing ? "Running Results" : "Final Results"
                }
                self.collectionView.reloadData()
            } else {
                log.error("[Error] Failed to update superlatives for playgroup id: \(self.playgroup.pid)")
            }
        }
        
        // Load did you know
        DataService.ds.getDidYouKnow(discipline: playgroup.title, did: playgroup.didYouKnowId) { (didSuccess, videoLink_) in
            if !didSuccess {
                showErrorAlert(vc: self, title: "Error", message: "There's an error loading the video. Please try again later.")
                return
            }
            self.shareLink = videoLink_.trim() + "?&playsinline=1"
            self.didYouKnowVideo.stopLoading()
            let videoWidth = UIScreen.main.bounds.width - 8.0 * 4 // Double margin from outside cell and within cell
            let videoHeight = 250.0 // This matches the constraints defined above
            self.didYouKnowVideo.loadHTMLString("<iframe width=\"\(videoWidth)\" height=\"\(videoHeight)\" src=\"\(self.shareLink)\" frameborder=\"0\" allowfullscreen></iframe>", baseURL: nil)
        }
    }

}
