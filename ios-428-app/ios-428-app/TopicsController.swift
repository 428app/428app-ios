//
//  TopicsController.swift
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

class TopicsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate let CELL_ID = "topicCell"
    
    open var topics = [Topic]()
    fileprivate lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = GRAY_UICOLOR
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.register(TopicCell.self, forCellReuseIdentifier: self.CELL_ID)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        self.view.backgroundColor = GRAY_UICOLOR
        self.navigationItem.title = "Classrooms"
        self.automaticallyAdjustsScrollViewInsets = false
        self.extendedLayoutIncludesOpaqueBars = true
        self.loadData()
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    deinit {
        self.countdownTimer.invalidate()
    }
    
    // MARK: Firebase
    
    fileprivate func loadData() {
        // TODO: Load classrooms from server
//        self.topics = loadTopics()
        emptyPlaceholderView.isHidden = false
        self.countdownTimer.invalidate()
        self.countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
        self.countdownTimer.fire()
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
        self.tableView.addSubview(self.emptyPlaceholderView)
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
        view.addSubview(tableView)
        view.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        view.addConstraintsWithFormat("V:[v0]|", views: tableView)
        self.setupEmptyPlaceholderView()
    }
    
    // MARK: Table view of classrooms
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! TopicCell
        let topic = topics[indexPath.row]
        cell.configureCell(topic: topic)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let topic = topics[indexPath.row]
        let controller = DiscussController()
        controller.topic = topic
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
