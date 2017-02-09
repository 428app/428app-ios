//
//  InboxController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit
import Firebase

class InboxController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "inboxCell"
    
    open var latestMessages: [InboxMessage] = [InboxMessage]() // Non-private so DataService can access
    
    fileprivate var inboxRefAndHandle: (FIRDatabaseReference, FIRDatabaseHandle)!
    fileprivate var recentMessageRefsAndHandles: [(FIRDatabaseReference, FIRDatabaseHandle)] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadFromFirebase()
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
        navigationItem.title = "Inbox"
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        
        // Check if there is an inboxToOpen from View Profile, if there is, open inbox
        if let inbox = inboxToOpen {
            inboxToOpen = nil
            let controller = ChatInboxController()
            controller.inbox = inbox
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(controller, animated: false)
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    deinit {
        for (ref, handle) in recentMessageRefsAndHandles {
            ref.removeObserver(withHandle: handle)
        }
        if inboxRefAndHandle != nil {
            inboxRefAndHandle.0.removeObserver(withHandle: inboxRefAndHandle.1)
        }
    }
    
    // MARK: Firebase
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading-large")!
        return CustomActivityIndicatorView(image: image)
    }()
    
    
    // MARK: Views for no chats
    
    fileprivate let emptyPlaceholderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4))
        view.isHidden = true
        return view
    }()
    
    fileprivate let inboxImage: UIImageView = {
        let image = #imageLiteral(resourceName: "inbox-empty")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let noChatsLbl: UIView = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "No private messages yet."
       return label
    }()
    
    fileprivate func setupEmptyPlaceholderView() {
        self.collectionView?.addSubview(self.emptyPlaceholderView)
        self.emptyPlaceholderView.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
        
        self.emptyPlaceholderView.addSubview(inboxImage)
        self.emptyPlaceholderView.addSubview(noChatsLbl)
        self.emptyPlaceholderView.addConstraintsWithFormat("H:[v0(60)]", views: inboxImage)
        self.emptyPlaceholderView.addConstraint(NSLayoutConstraint(item: inboxImage, attribute: .centerX, relatedBy: .equal, toItem: self.emptyPlaceholderView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        self.emptyPlaceholderView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: noChatsLbl)
        
        self.emptyPlaceholderView.addConstraintsWithFormat("V:|-8-[v0(60)]-5-[v1]", views: inboxImage, noChatsLbl)
    }
    
    fileprivate func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(InboxCell.self, forCellWithReuseIdentifier: CELL_ID)
        
        self.setupEmptyPlaceholderView()
        
        self.collectionView?.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.08 * self.view.frame.height)
    }
    
    fileprivate func loadFromFirebase() {

        self.activityIndicator.startAnimating()
        
        // Note that there is no pagination with private chats, as we don't expect the list to be obscenely large at the rate of up to 7 new classmates per week
        
        self.inboxRefAndHandle = DataService.ds.observeInboxes { (isSuccess, inboxes) in
            
            if inboxes.count == 0 {
                // No chats yet, display placeholder and stop animating loader
                self.emptyPlaceholderView.isHidden = false
                self.activityIndicator.stopAnimating()
                return
            }
            
            self.emptyPlaceholderView.isHidden = true
            
            // Remove all recent chat observers and reappend
            for (ref, handle) in self.recentMessageRefsAndHandles {
                ref.removeObserver(withHandle: handle)
            }
            
            self.latestMessages = []
            
            for chat in inboxes {
                // Register handlers for each of these
                if !isSuccess {
                    log.error("[Error] Can't pull all private chats")
                    return
                }
                self.recentMessageRefsAndHandles.append(DataService.ds.observeRecentInbox(inbox: chat, completed: {
                    (isSuccess, inbox) in
                    
                    self.activityIndicator.stopAnimating()
                    
                    if !isSuccess || inbox == nil {
                        log.error("[Error] Can't pull a certain connection")
                        return
                    }
                    
                    // Find the messages belonging to this private chat, remove them, then add this
                    self.latestMessages = self.latestMessages.filter() {$0.inbox.uid != inbox!.uid}
                    
                    // Log new messages coming in
                    self.latestMessages.append(contentsOf: inbox!.messages)
                    
                    // Sort latest messages based on time
                    // I know, not the most efficient. Could have done a binary search and insert, but frontend 
                    // efficiency is not a concern given the limited number of connections.
                    self.latestMessages.sort(by: { (m1, m2) -> Bool in
                        return m1.date.compare(m2.date) == .orderedDescending
                    })
                    self.collectionView?.reloadData()
                }))
            }
        }
    }
    
    // MARK: Collection view 
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.latestMessages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! InboxCell
        let message = self.latestMessages[indexPath.item]
        cell.configureCell(messageObj: message)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 92)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let controller = ChatInboxController()
        controller.inbox = self.latestMessages[indexPath.item].inbox
        navigationController?.pushViewController(controller, animated: true)
    }
}
