//
//  ConnectionsController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit
import Firebase

class ConnectionsController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "connectionCell"
    
    open var latestMessages: [Message] = [Message]() // Non-private so DataService can access
    
    fileprivate var firebaseRefsAndHandles: [(FIRDatabaseReference, FIRDatabaseHandle)] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupFirebase()
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
    
    deinit {
        for (ref, handle) in firebaseRefsAndHandles {
            ref.removeObserver(withHandle: handle)
        }
    }
    
    // MARK: Firebase
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading-large")!
        return CustomActivityIndicatorView(image: image)
    }()
    
    func setupFirebase() {
        
        // Activity indicator before posts come in
        self.collectionView?.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.08 * self.view.frame.height)
        self.activityIndicator.startAnimating()
        
        // Note that there is no pagination with connections, because at the rate of 1 new connection a day, 
        // this list will not likely become obscenely large
        self.firebaseRefsAndHandles.append(DataService.ds.observeConnections { (isSuccess, connections) in
            for conn in connections {
                // Register handlers for each of these
                if !isSuccess {
                    log.error("[Error] Can't pull all connections")
                    return
                }
                self.firebaseRefsAndHandles.append(DataService.ds.observeRecentChat(connection: conn, completed: { (isSuccess, connection) in
                    if !isSuccess || connection == nil {
                        log.error("[Error] Can't pull a certain connection")
                        return
                    }
                    
                    // Find the messages belonging to this connection, remove them, then add this
                    self.latestMessages = self.latestMessages.filter() {$0.connection.uid != connection!.uid}
                    
                    // Log new messages coming in
                    self.latestMessages.append(contentsOf: connection!.messages)
                    
                    // Sort latest messages based on time
                    // I know, not the most efficient. Could have done a binary search and insert, but frontend 
                    // efficiency is not a concern given the limited number of connections.
                    self.latestMessages.sort(by: { (m1, m2) -> Bool in
                        return m1.date.compare(m2.date) == .orderedDescending
                    })
                    self.collectionView?.reloadData()
                    
                    self.activityIndicator.stopAnimating()
                }))
            }
        })
    }
    
    // MARK: Collection view 
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.latestMessages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ConnectionCell
        cell.request?.cancel()
        let message = self.latestMessages[indexPath.item]
        cell.configureCell(messageObj: message)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 92)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let controller = ChatController()
        controller.connection = self.latestMessages[indexPath.item].connection
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: Used by extension to generate data
    open var connectionToMinutesAgo = [String: Double]()
    open var connectionToLatestMessage = [String: Message]()
    open var midAutoId = 1
    
}
