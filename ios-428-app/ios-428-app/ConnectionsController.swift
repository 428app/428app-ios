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
    
    open var latestMessages: [ConnectionMessage] = [ConnectionMessage]() // Non-private so DataService can access
    
    fileprivate var connectionsRefAndHandle: (FIRDatabaseReference, FIRDatabaseHandle)!
    fileprivate var recentMessageRefsAndHandles: [(FIRDatabaseReference, FIRDatabaseHandle)] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadFromFirebase()
        
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
        navigationItem.title = "Connections"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        for (ref, handle) in recentMessageRefsAndHandles {
            ref.removeObserver(withHandle: handle)
        }
        connectionsRefAndHandle.0.removeObserver(withHandle: connectionsRefAndHandle.1)
        self.countdownTimer.invalidate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        
    }
    
    // MARK: Firebase
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading-large")!
        return CustomActivityIndicatorView(image: image)
    }()
    
    
    fileprivate let emptyPlaceholderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4))
        view.isHidden = true
        return view
    }()
    
    fileprivate let logo428: UIImageView = {
       let logo = #imageLiteral(resourceName: "logo")
        let imageView = UIImageView(image: logo)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let timerLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_XXLARGE
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let until428Label: UILabel = {
       let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        label.textColor = GREEN_UICOLOR
        label.text = "until 4:28pm"
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let infoIcon: UIImageView = {
       let icon = #imageLiteral(resourceName: "info")
        let imageView = UIImageView(image: icon)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let connectionIsOnTheWayLabel: UIView = {
        let label = UILabel()
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "Your connection is on the way..."
       return label
    }()
    
    fileprivate func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(ConnectionCell.self, forCellWithReuseIdentifier: CELL_ID)
        
        self.setupEmptyPlaceholderView()
        
        self.collectionView?.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.08 * self.view.frame.height)
    }
    
    fileprivate func setupEmptyPlaceholderView() {
        self.collectionView?.addSubview(self.emptyPlaceholderView)
        self.emptyPlaceholderView.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.03 * self.view.frame.height)
        
        self.emptyPlaceholderView.addSubview(logo428)
        self.emptyPlaceholderView.addSubview(timerLabel)
        self.emptyPlaceholderView.addSubview(until428Label)
        self.emptyPlaceholderView.addConstraintsWithFormat("H:[v0(60)]", views: logo428)
        self.emptyPlaceholderView.addConstraint(NSLayoutConstraint(item: logo428, attribute: .centerX, relatedBy: .equal, toItem: self.emptyPlaceholderView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        self.emptyPlaceholderView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: timerLabel)
        self.emptyPlaceholderView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: until428Label)
        
        let infoContainer = UIView()
        infoContainer.addSubview(infoIcon)
        infoContainer.addSubview(connectionIsOnTheWayLabel)
        infoContainer.addConstraintsWithFormat("H:|[v0(14)]-4-[v1]|", views: infoIcon, connectionIsOnTheWayLabel)
        infoContainer.addConstraintsWithFormat("V:|-1-[v0(14)]", views: infoIcon)
        infoContainer.addConstraintsWithFormat("V:|[v0(18)]|", views: connectionIsOnTheWayLabel)
        self.emptyPlaceholderView.addSubview(infoContainer)
        self.emptyPlaceholderView.addConstraint(NSLayoutConstraint(item: infoContainer, attribute: .centerX, relatedBy: .equal, toItem: self.emptyPlaceholderView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        
        self.emptyPlaceholderView.addConstraintsWithFormat("V:|-8-[v0(60)]-5-[v1]-2-[v2]-8-[v3]", views: logo428, timerLabel, until428Label, infoContainer)
    }
    
    func updateTime() {
        let now = Date()
        let calendar = Calendar.current
        let components = DateComponents(calendar: calendar, hour: 16, minute: 28)
        guard let next438 = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else {
            return
        }
        let diff = calendar.dateComponents([.hour, .minute, .second], from: now, to: next438)
        if let hours = diff.hour, let minutes = diff.minute, let seconds = diff.second {
            let hoursString = hours < 10 ? "0\(hours)" : "\(hours)"
            let minutesString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
            self.timerLabel.text = "\(hoursString):\(minutesString):\(secondsString)"
        }
    }
    
    fileprivate lazy var countdownTimer: Timer = {
       return Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
    }()
    
    fileprivate func loadFromFirebase() {

        self.activityIndicator.startAnimating()
        
        // Note that there is no pagination with connections, because at the rate of 1 new connection a day, 
        // this list will not likely become obscenely large
        self.connectionsRefAndHandle = DataService.ds.observeConnections { (isSuccess, connections) in
            if connections.count == 0 {
                // New user, empty placeholder view, and fire countdown timer
                self.emptyPlaceholderView.isHidden = false
                self.countdownTimer.invalidate()
                self.countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
                self.countdownTimer.fire()
                self.activityIndicator.stopAnimating()
            } else {
                self.emptyPlaceholderView.isHidden = true
            }
            
            // Remove all recent chat observers and reappend
            for (ref, handle) in self.recentMessageRefsAndHandles {
                ref.removeObserver(withHandle: handle)
            }
            
            self.latestMessages = []
            
            for conn in connections {
                // Register handlers for each of these
                if !isSuccess {
                    log.error("[Error] Can't pull all connections")
                    return
                }
                self.recentMessageRefsAndHandles.append(DataService.ds.observeRecentChat(connection: conn, completed: {
                    (isSuccess, connection) in
                    
                    self.activityIndicator.stopAnimating()
                    
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
                }))
            }
        }
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
        collectionView.deselectItem(at: indexPath, animated: false)
        let controller = ChatController()
        controller.connection = self.latestMessages[indexPath.item].connection
        navigationController?.pushViewController(controller, animated: true)
    }
}
