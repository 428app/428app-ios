//
//  AnswersController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Social

class AnswersController: UITableViewController {
    
    // Tableview instead of collectionview used as we need dynamic height of cells
    
    fileprivate let ANSWERCELL_ID = "answerCell"
    fileprivate let VIDEOANSWERCELL_ID = "videoAnswerCell"
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(shareOnFB), name: NOTIF_SHAREANSWER, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
        NotificationCenter.default.removeObserver(self, name: NOTIF_SHAREANSWER, object: nil)
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
        tableView.register(VideoAnswerCell.self, forCellReuseIdentifier: VIDEOANSWERCELL_ID)
        tableView.register(AnswerCell.self, forCellReuseIdentifier: ANSWERCELL_ID)
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
        let question = questions[indexPath.item]
        if question.isVideo {
            let cell = tableView.dequeueReusableCell(withIdentifier: VIDEOANSWERCELL_ID, for: indexPath) as! VideoAnswerCell
            cell.configureCell(questionObj: question)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ANSWERCELL_ID, for: indexPath) as! AnswerCell
            cell.configureCell(questionObj: question)
            return cell
        }
    }
    
    // MARK: Share
    
    func shareOnFB(notif: Notification) {
        log.info("shared received")
        guard let userInfo = notif.userInfo as? [String: Any], let shareLink = userInfo["shareLink"] as? String else {
            return
        }
        log.info("pass")
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            log.info("about to share")
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                log.info("shared!")
                socialController.add(#imageLiteral(resourceName: "logo"))
                let url = URL(string: shareLink)
                socialController.add(url)
                self.present(socialController, animated: true, completion: {})
            }
        }
    }
}


class VideoAnswerCell: BaseTableViewCell, UIWebViewDelegate {
    
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
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let answerLbl: UILabel = {
        let label = UILabel()
        label.text = "Answer"
        label.font = FONT_HEAVY_LARGE
        label.textColor = RED_UICOLOR
        label.textAlignment = .left
        return label
    }()
    
    fileprivate lazy var answerVideo: UIWebView = {
        let webView = UIWebView()
        webView.delegate = self
        webView.allowsInlineMediaPlayback = true
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        return webView
    }()
    
    fileprivate lazy var placeHolderVideo: UIView = {
        let view = UIView()
        view.backgroundColor = GRAY_UICOLOR
        return view
    }()
    
    fileprivate lazy var activityIndicator: CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading")!.maskWithColor(color: RED_UICOLOR)!
        let activityIndicatorView = CustomActivityIndicatorView(image: image)
        activityIndicatorView.isHidden = true
        return activityIndicatorView
    }()
    
    // MARK: Share
    
    fileprivate lazy var fbButton: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.setBackgroundColor(color: FB_BLUE_UICOLOR, forState: .normal)
        btn.setBackgroundColor(color: UIColor(red: 50/255.0, green: 75/255.0, blue: 128/255.0, alpha: 1.0), forState: .highlighted) // Darker shade of blue
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitle("Share on Facebook", for: .normal)
        btn.addTarget(self, action: #selector(shareOnFb), for: .touchUpInside)
        btn.layer.cornerRadius = 5.0
        btn.clipsToBounds = true
        return btn
    }()
    
    func shareOnFb() {
        NotificationCenter.default.post(name: NOTIF_SHAREANSWER, object: nil, userInfo: ["shareLink": question.answer])
    }
    
    // MARK: Web view delegates
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        log.info("Finish loading")
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        placeHolderVideo.isHidden = true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        log.info("Starting to load")
        // Padding to remove the ugly default left padding of UIWebViews
        let negativePadding = "document.body.style.margin='0';document.body.style.padding = '0'"
        answerVideo.stringByEvaluatingJavaScript(from: negativePadding)
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        placeHolderVideo.isHidden = false
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        log.info("Fail to load with error: \(error)")
        activityIndicator.stopAnimating()
    }
    
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
        containerView.addSubview(answerVideo)
        containerView.addSubview(fbButton)
        
        containerView.addConstraintsWithFormat("V:|-8-[v0(20)]-8-[v1]-8-[v2(20)]-8-[v3(250)]-8-[v4(40)]-8-|", views: questionLbl, questionText,  answerLbl, answerVideo, fbButton)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerVideo)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: fbButton)
        
        answerVideo.addSubview(placeHolderVideo)
        answerVideo.addConstraintsWithFormat("H:|[v0]|", views: placeHolderVideo)
        answerVideo.addConstraintsWithFormat("V:|[v0]|", views: placeHolderVideo)
        
        answerVideo.addSubview(activityIndicator)
        answerVideo.translatesAutoresizingMaskIntoConstraints = false
        let topMargin = (250/2.0) - activityIndicator.frame.height/2.0 - 4.0
        answerVideo.addConstraintsWithFormat("V:|-\(topMargin)-[v0]", views: activityIndicator)
        let leftMargin = (UIScreen.main.bounds.width - 8.0*4)/2.0 - activityIndicator.frame.width/2.0 - 8.0
        answerVideo.addConstraintsWithFormat("H:|-\(leftMargin)-[v0]", views: activityIndicator)
        
        addSubview(containerView)
        addConstraintsWithFormat("H:|-12-[v0]-12-|", views: containerView)
        addConstraintsWithFormat("V:|-8-[v0]-8-|", views: containerView)
    }
    
    func configureCell(questionObj: Question) {
        self.question = questionObj
        questionText.text = question.question
        let answerLink: String = question.answer.trim() + "?&playsinline=1"
        self.answerVideo.stopLoading()
        let videoWidth = UIScreen.main.bounds.width - 8.0 * 4 // Double margin from outside cell and within cell
        let videoHeight = 250.0 // This matches the constraints defined above
        self.answerVideo.loadHTMLString("<iframe width=\"\(videoWidth)\" height=\"\(videoHeight)\" src=\"\(answerLink)\" frameborder=\"0\" allowfullscreen></iframe>", baseURL: nil)
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
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let answerLbl: UILabel = {
        let label = UILabel()
        label.text = "Answer"
        label.font = FONT_HEAVY_LARGE
        label.textColor = RED_UICOLOR
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
