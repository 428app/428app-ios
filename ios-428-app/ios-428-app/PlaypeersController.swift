//
//  PlaypeersController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class PlaypeersController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "playpeersProfileCell"
    
    open var playpeers: [Profile]!
    
    let interactor = Interactor() // Used for transitioning to and from ProfileController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Playpeers"
        self.view.backgroundColor = RED_UICOLOR
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
        // Sort playpeers by name alphabetically
        self.playpeers = self.playpeers.sorted{($0.name < $1.name)}
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: RED_UICOLOR), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(sendMessageFromProfile), name: NOTIF_SENDMESSAGE, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
        NotificationCenter.default.removeObserver(self, name: NOTIF_SENDMESSAGE, object: nil)
    }
    
    func sendMessageFromProfile(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: Inbox], let inbox = userInfo["inbox"] {
            // Switch to Inbox tab, and let the rest of the transition happen in InboxController, based on the side effect inboxToOpen
            inboxToOpen = inbox // This must come before setting the tab selected index, or everything will screw up
            self.tabBarController?.selectedIndex = 2
        }
    }
    
    fileprivate func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = RED_UICOLOR
        collectionView?.bounces = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.register(PlaypeersProfileCell.self, forCellWithReuseIdentifier: CELL_ID)
        collectionView?.contentInset.top = 20.0
    }
    // MARK: Collection view
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.playpeers.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! PlaypeersProfileCell
        let playpeer = self.playpeers[indexPath.item]
        cell.configureCell(profileObj: playpeer)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 2 cells per row
        return CGSize(width: UIScreen.main.bounds.width / 2.0, height: 168.0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PlaypeersProfileCell
        cell.changeColor()
        let playpeer = self.playpeers[indexPath.item]
        let controller = ProfileController()
        controller.transitioningDelegate = self
        controller.interactor = interactor
        controller.profile = playpeer
        controller.modalTransitionStyle = .coverVertical
        controller.modalPresentationStyle = .overFullScreen
        self.present(controller, animated: true, completion: nil)
    }
    
}