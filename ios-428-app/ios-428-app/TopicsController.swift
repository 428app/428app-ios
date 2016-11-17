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
        self.navigationItem.title = "Topics"
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
    
    fileprivate func loadData() {
        self.topics = loadTopics()
    }
    
    fileprivate func setupViews() {
        view.addSubview(tableView)
        view.addSubview(segmentedControl)
        
        view.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: segmentedControl)
        view.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        
        view.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 12.0))
        
        view.addConstraintsWithFormat("V:[v0(30)]-8-[v1]|", views: segmentedControl, tableView)
    }
    
    // MARK: Segment
    
    fileprivate enum SEGMENT_TYPE: Int {
        case posted = 0, replied, hot
    }
    
    fileprivate var chosenSegment: SEGMENT_TYPE = .posted
    
    fileprivate lazy var segmentedControl: UISegmentedControl = {
        let options = ["Posted", "Replied", "Hot"]
        let control = UISegmentedControl(items: options)
        let frame = UIScreen.main.bounds
        control.setTitleTextAttributes([NSFontAttributeName: FONT_HEAVY_MID], for: .normal)
        control.selectedSegmentIndex = 0
        control.layer.cornerRadius = 4.0
        control.backgroundColor = UIColor.white
        control.isEnabled = true
        control.isOpaque = true
        control.isHidden = false
        control.tintColor = GREEN_UICOLOR
        control.addTarget(self, action: #selector(changeSegment), for: .valueChanged)
        return control
    }()
    
    func changeSegment(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case SEGMENT_TYPE.posted.rawValue:
            topics.sort{$0.date.compare($1.date) == .orderedDescending }
        case SEGMENT_TYPE.replied.rawValue:
            topics.sort{$0.latestMessageDate.compare($1.latestMessageDate) == .orderedDescending }
        case SEGMENT_TYPE.hot.rawValue:
            topics.sort{$0.topicMessages.count > $1.topicMessages.count }
        default:
            return
        }
        self.reloadTableViewAnimated()
    }
    
    fileprivate func reloadTableViewAnimated() {
        let range = NSMakeRange(0, tableView.numberOfSections)
        let sections = NSIndexSet(indexesIn: range)
        tableView.reloadSections(sections as IndexSet, with: .automatic)
    }
    
    // MARK: Table view
    
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
