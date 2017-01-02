//
//  RatingsController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class RatingsController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "ratingCell"
    
    open var ratings: [Rating]!
    open var classmates: [Profile]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Ratings"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(submitRatings))
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.view.backgroundColor = GREEN_UICOLOR
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
        NotificationCenter.default.addObserver(self, selector: #selector(selectRating), name: NOTIF_RATINGSELECTED, object: nil)
        checkToEnableSubmitRating()
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
    
    fileprivate func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = GREEN_UICOLOR
        collectionView?.bounces = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.register(RatingCell.self, forCellWithReuseIdentifier: CELL_ID)
    }
    // MARK: Collection view
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.ratings.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! RatingCell
        let rating = self.ratings[indexPath.item]
        cell.configureCell(ratingObj: rating)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 168.0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let rating = self.ratings[indexPath.item]
        // TODO: Have to pass over selected profile to highlight
        let modalController = ModalVoteController()
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .crossDissolve
        modalController.ratingName = rating.ratingName
        modalController.userVotedFor = rating.userVotedFor
        modalController.classmates = self.classmates
        self.present(modalController, animated: true, completion: nil)
    }
    
    // MARK: Ratings
    
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
                    self.collectionView?.reloadData()
                }
            }
        }
        checkToEnableSubmitRating()
    }
    
    func submitRatings() {
        // TODO: Dismiss this controller and immediately relaunch under ResultsController
        self.navigationController?.popViewController(animated: true)
    }

}
