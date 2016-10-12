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
    
    open var messages: [Message]? // Non-private so CoreDataService can access
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupData() // Setting up dummy data from CoreDataService
        navigationItem.title = "Connections"
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
        if let count = messages?.count {
            return count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ConnectionCell
        let message = self.messages?[indexPath.item]
        cell.configureCell(messageObj: message)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 92)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = ChatController()
        controller.friend = self.messages?[indexPath.item].friend
        navigationController?.pushViewController(controller, animated: true)
    }
}
