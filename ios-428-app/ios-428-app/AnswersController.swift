//
//  AnswersController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class AnswersController: UITableViewController {
    
    // Tableview instead of collectionview used as we need dynamic height of cells
    
    fileprivate let CELL_ID = "answerCell"
    
    open var questions: [Question]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do not show the most recent answer (the first answer, as it has already been sorted)
        questions = Array(questions.dropFirst(1))
        
        self.navigationItem.title = "Answers"
        self.view.backgroundColor = GREEN_UICOLOR
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: GREEN_UICOLOR), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
    }
    
    fileprivate func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = GREEN_UICOLOR
        tableView.bounces = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(AnswerCell.self, forCellReuseIdentifier: CELL_ID)
        tableView.contentInset.top = 12.0
        // Table view cells with dynamic heights
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300.0
    }
    
    // MARK: Table view
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! AnswerCell
        let question = questions[indexPath.item]
        cell.configureCell(questionObj: question)
        return cell
    }
    
}

class AnswerCell: BaseTableViewCell {
    
    fileprivate var question: Question!
    
    fileprivate let questionLbl: UILabel = {
       let label = UILabel()
        label.text = "Question"
        label.font = FONT_HEAVY_LARGE
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let questionText: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let answerLbl: UILabel = {
        let label = UILabel()
        label.text = "Answer"
        label.font = FONT_HEAVY_LARGE
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let answerText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    override func setupViews() {
        backgroundColor = GREEN_UICOLOR
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.layer.cornerRadius = 4.0
        let SHADOW_COLOR: CGFloat =  157.0 / 255.0
        containerView.layer.shadowColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).cgColor
        containerView.layer.shadowOpacity = 0.6
        containerView.layer.shadowRadius = 2.0
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        containerView.addSubview(questionLbl)
        containerView.addSubview(questionText)
        containerView.addSubview(answerLbl)
        containerView.addSubview(answerText)
        
        containerView.addConstraintsWithFormat("V:|-8-[v0(20)]-8-[v1]-8-[v2(20)]-8-[v3]-8-|", views: questionLbl, questionText,  answerLbl, answerText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerText)
        
        addSubview(containerView)
        addConstraintsWithFormat("H:|-12-[v0]-12-|", views: containerView)
        addConstraintsWithFormat("V:|-8-[v0]-8-|", views: containerView)
    }
    
    func configureCell(questionObj: Question) {
        self.question = questionObj
        questionText.text = question.question
        answerText.text = question.answer
    }
}
