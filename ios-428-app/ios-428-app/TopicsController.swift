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
    
    fileprivate var topics = [Topic]()
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
        self.loadData()
        self.setupViews()
//        tableView.layoutIfNeeded()
//        tableView.setNeedsLayout()
//        tableView.reloadData()

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
        
        view.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        view.addConstraintsWithFormat("V:|-8-[v0]|", views: tableView)
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
}
