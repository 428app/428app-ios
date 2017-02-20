//
//  ClassroomsController.swift
//  ios-428-app
//
//  I use a table view controller when I need dynamically sized cells, 
//  otherwise collection view controller.
//
//  Created by Leonard Loo on 10/19/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ClassroomsController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Firebase
    fileprivate var allClassFirebase: (FIRDatabaseReference, FIRDatabaseHandle)!
    fileprivate var classesFirebase: [String: (FIRDatabaseReference, FIRDatabaseHandle)] = [:]
    
    fileprivate let CELL_ID = "classroomCell"
    
    open var classrooms = [Classroom]()
    
    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = GRAY_UICOLOR
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.register(ClassroomCell.self, forCellWithReuseIdentifier: self.CELL_ID)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        self.view.backgroundColor = GRAY_UICOLOR
        self.navigationItem.title = "Classrooms"
        self.automaticallyAdjustsScrollViewInsets = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
        self.loadClassrooms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = GREEN_UICOLOR
        self.tabBarController?.tabBar.isHidden = false
        DataService.ds.getUserHasNewClassroom { (classroomTitle) in
            if classroomTitle != nil {
                self.showNewClassroomAlert(classroomTitle: classroomTitle!)
            }
        }
    }
    
    deinit {
        self.countdownTimer.invalidate()
        for (ref, handle) in self.classesFirebase.values {
            ref.removeObserver(withHandle: handle)
        }
        if allClassFirebase != nil {
            self.allClassFirebase.0.removeObserver(withHandle: allClassFirebase.1)
        }
    }
    
    // MARK: Firebase
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading-large")!
        return CustomActivityIndicatorView(image: image)
    }()
    
    fileprivate func minAgo(minutesAgo: Double) -> Date {
        return Date().addingTimeInterval(-minutesAgo * 60.0)
    }
    
    fileprivate func loadClassrooms() {
        
        self.activityIndicator.startAnimating()
        
        // Check if there are any classrooms in the first place
        DataService.ds.checkIfThereAreAnyClassrooms { (hasClassroom) in
            if !hasClassroom {
                // No classrooms yet, display placeholder and stop animating loader
                self.enableEmptyPlaceholder(enable: true)
                self.activityIndicator.stopAnimating()
            } else {
                self.enableEmptyPlaceholder(enable: false)
            }
        }
        
        self.allClassFirebase = DataService.ds.observeClassroomAdded { (isSuccess, cid) in
            
            if !isSuccess || cid.isEmpty {
                // No classrooms yet, display placeholder and stop animating loader
                self.enableEmptyPlaceholder(enable: true)
                self.activityIndicator.stopAnimating()
                return
            }
            
            self.enableEmptyPlaceholder(enable: false)
            
            // Reset single classroom observer
            if self.classesFirebase[cid] != nil {
                self.classesFirebase[cid]!.0.removeObserver(withHandle: self.classesFirebase[cid]!.1)
            }
            self.classesFirebase[cid] = DataService.ds.observeClassroomUpdates(cid: cid, completed: { (isSuccess2, classroom_) in
                self.activityIndicator.stopAnimating()
                if !isSuccess2 || classroom_ == nil {
                    return
                }
                let classroom = classroom_!
                self.classrooms = self.classrooms.filter{$0.cid != classroom.cid}  // If class already added, then remove it first
                self.classrooms.append(classroom)
                self.classrooms = self.classrooms.sorted{$0.timeReplied > $1.timeReplied}
                self.collectionView.reloadDataAnimatedForSingleSection()
            })
        }
    }
    
    fileprivate func showNewClassroomAlert(classroomTitle: String) {
        let alertController = NewClassroomAlertController()
        alertController.discipline = classroomTitle
        alertController.modalPresentationStyle = .overFullScreen
        alertController.modalTransitionStyle = .crossDissolve
        self.present(alertController, animated: true, completion: {
            alertController.view.tintColor = GREEN_UICOLOR
        })
    }
    
    fileprivate func enableEmptyPlaceholder(enable: Bool) {
        if enable {
            self.emptyPlaceholderView.isHidden = false
            self.countdownTimer.invalidate()
            self.countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
            self.countdownTimer.fire()
        } else {
            self.emptyPlaceholderView.isHidden = true
            self.countdownTimer.invalidate()
        }
    }
    
    // MARK: Views for no classrooms
    
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
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.darkGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate let classroomIsOnTheWayLabel: UIView = {
        let label = UILabel()
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "Your classroom is on the way..."
        return label
    }()
    
    fileprivate func setupEmptyPlaceholderView() {
        self.collectionView.addSubview(self.emptyPlaceholderView)
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
        infoContainer.addSubview(classroomIsOnTheWayLabel)
        infoContainer.addConstraintsWithFormat("H:|[v0(14)]-4-[v1]|", views: infoIcon, classroomIsOnTheWayLabel)
        infoContainer.addConstraintsWithFormat("V:|-1-[v0(14)]", views: infoIcon)
        infoContainer.addConstraintsWithFormat("V:|[v0(18)]|", views: classroomIsOnTheWayLabel)
        self.emptyPlaceholderView.addSubview(infoContainer)
        self.emptyPlaceholderView.addConstraint(NSLayoutConstraint(item: infoContainer, attribute: .centerX, relatedBy: .equal, toItem: self.emptyPlaceholderView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        
        self.emptyPlaceholderView.addConstraintsWithFormat("V:|-8-[v0(60)]-5-[v1]-2-[v2]-8-[v3]", views: logo428, timerLabel, until428Label, infoContainer)
    }
    
    fileprivate func setupViews() {
        view.addSubview(collectionView)
        view.addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        view.addConstraintsWithFormat("V:|[v0]|", views: collectionView)
        self.setupEmptyPlaceholderView()
        self.collectionView.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.08 * self.view.frame.height)
    }
    
    // MARK: Collection view of classrooms
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // NOTE: This is crucial, there must only be 1 section for the collection view's reload data to animate
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return classrooms.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ClassroomCell
        let classroom = classrooms[indexPath.row]
        cell.configureCell(classroom: classroom)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Fixed height
        return CGSize(width: view.frame.width, height: 282.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let classroom = classrooms[indexPath.row]
        let controller = ChatClassroomController()
        controller.classroom = classroom
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ClassroomCell
        cell.setSelectedColors(isSelected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ClassroomCell
        cell.setSelectedColors(isSelected: false)
    }

    
}
