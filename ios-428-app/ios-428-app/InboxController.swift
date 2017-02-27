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
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
        navigationItem.title = "Inbox"
        self.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.barTintColor = GREEN_UICOLOR
        // Check if there is an inboxToOpen from View Profile, if there is, open inbox
        if let inbox = inboxToOpen {
            inboxToOpen = nil
            let controller = ChatInboxController()
            controller.inbox = inbox
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(controller, animated: false)
        }
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

    fileprivate func loadData() {
        
        self.activityIndicator.startAnimating()
        
        // Note that there is no pagination with private chats, as we don't expect the list to be obscenely large
        
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
            
            for inbox in inboxes {
                // Register handlers for each of these
                if !isSuccess {
                    log.error("[Error] Can't pull all private chats")
                    return
                }
                self.recentMessageRefsAndHandles.append(DataService.ds.observeRecentInbox(inbox: inbox, completed: {
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
                    self.collectionView?.reloadDataAnimatedForSingleSection()
                }))
            }
        }
    }

    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading-large")!
        return CustomActivityIndicatorView(image: image)
    }()
    
    // MARK: Views for no chats
    
    fileprivate lazy var emptyPlaceholderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4))
        view.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(changePlaceholderColor))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        return view
    }()
    
    func changePlaceholderColor() {
        if self.noChatsLbl.textColor == GREEN_UICOLOR {
            self.inboxImage.image = self.inboxImage.image?.maskWithColor(color: RED_UICOLOR)
            self.noChatsLbl.textColor = RED_UICOLOR
        } else {
            self.inboxImage.image = self.inboxImage.image?.maskWithColor(color: GREEN_UICOLOR)
            self.noChatsLbl.textColor = GREEN_UICOLOR
        }
    }
    
    fileprivate let inboxImage: UIImageView = {
        let image = #imageLiteral(resourceName: "inbox-empty")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let noChatsLbl: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .center
        label.text = "No private messages yet."
       return label
    }()
    
    fileprivate let descriptionLbl: UILabel = {
       let label = UILabel()
        label.font = FONT_HEAVY_MID
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let str = NSMutableAttributedString(string: "Send your classmates private messages by visiting their profiles in your classrooms.", attributes: [NSForegroundColorAttributeName: UIColor.darkGray, NSParagraphStyleAttributeName: paragraphStyle])
        label.attributedText = str
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate func setupEmptyPlaceholderView() {
        self.collectionView?.addSubview(self.emptyPlaceholderView)
        self.emptyPlaceholderView.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 12.0)
        
        self.emptyPlaceholderView.addSubview(inboxImage)
        self.emptyPlaceholderView.addSubview(noChatsLbl)
        self.emptyPlaceholderView.addSubview(descriptionLbl)
        self.emptyPlaceholderView.addConstraintsWithFormat("H:[v0(60)]", views: inboxImage)
        self.emptyPlaceholderView.addConstraint(NSLayoutConstraint(item: inboxImage, attribute: .centerX, relatedBy: .equal, toItem: self.emptyPlaceholderView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        self.emptyPlaceholderView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: noChatsLbl)
        self.emptyPlaceholderView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: descriptionLbl)
        
        self.emptyPlaceholderView.addConstraintsWithFormat("V:|-8-[v0(60)]-5-[v1(30)]-5-[v2]", views: inboxImage, noChatsLbl, descriptionLbl)
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
    
    // MARK: Collection view 
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // NOTE: This is crucial, there must only be 1 section for the collection view's reload data to animate
        return 1
    }
    
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
        let inbox = self.latestMessages[indexPath.item].inbox
        controller.inbox = inbox
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
}
