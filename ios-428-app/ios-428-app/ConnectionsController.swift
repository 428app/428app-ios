//
//  ConnectionsController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class ConnectionsController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "connectionCell"
    
    open var latestMessages: [Message] = [Message]() // Non-private so DataService can access
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupData() // Setting up dummy data from DataService
        navigationItem.title = "Connections"
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(ConnectionCell.self, forCellWithReuseIdentifier: CELL_ID)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: Collection view 
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.latestMessages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ConnectionCell
        let message = self.latestMessages[indexPath.item]
        cell.configureCell(messageObj: message)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 92)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = ChatController()
        controller.friend = self.latestMessages[indexPath.item].friend
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: Used by extension to generate data
    open var friendToMinutesAgo = [String: Double]()
    open var friendToLatestMessage = [String: Message]()
    open var midAutoId = 1
    
//    func collec
    
}
