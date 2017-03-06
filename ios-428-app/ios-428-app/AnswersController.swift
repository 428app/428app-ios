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
    
    fileprivate var questions = [Question]()
    open var playgroup: Playgroup!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Answers"
        self.view.backgroundColor = GREEN_UICOLOR
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
        self.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: GREEN_UICOLOR), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
        if hasPromptForAnswerVote() {
            self.showPromptForAnswerVote()
            setPromptForAnswerVote(hasPrompt: false)
        }
        self.registerObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
        self.unregisterObservers()
    }
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(shareOnFB), name: NOTIF_SHAREANSWER, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(voteAnswer), name: NOTIF_VOTEANSWER, object: nil)
    }
    
    fileprivate func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NOTIF_SHAREANSWER, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_VOTEANSWER, object: nil)
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
        
        self.view.addSubview(globalActivityIndicator)
        globalActivityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 0.12 * self.view.frame.height)
    }
    
    // MARK: Firebase
    
    fileprivate lazy var globalActivityIndicator: CustomActivityIndicatorView = {
        let image : UIImage = UIImage(named: "loading-large")!.maskWithColor(color: UIColor.white)!
        let activityIndicatorView = CustomActivityIndicatorView(image: image)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.isHidden = true
        return activityIndicatorView
    }()
    
    fileprivate func loadData() {
        globalActivityIndicator.startAnimating()
        // Load questions and answers
        DataService.ds.getQuestionsAndAnswers(playgroup: self.playgroup) { (isSuccess, updatedPlaygroup) in
            self.globalActivityIndicator.stopAnimating()
            if !isSuccess {
                showErrorAlert(vc: self, title: "Error", message: "We could not get the class' answers. Please try again later.")
                return
            }
            self.playgroup = updatedPlaygroup
            self.questions = self.playgroup.questions
            
            // Do not show the most recent answer (the first answer, as it has already been sorted)
            self.questions = Array(self.questions.dropFirst(1))
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: Vote for answers
    
    fileprivate func showPromptForAnswerVote() {
        let alertController = VoteAnswerPromptAlertController()
        alertController.modalPresentationStyle = .overFullScreen
        alertController.modalTransitionStyle = .crossDissolve
        self.present(alertController, animated: true, completion: nil)
    }
    
    func voteAnswer(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: Any], let qid = userInfo["qid"] as? String, let userVoteInt = userInfo["userVote"] as? Int {
            DataService.ds.voteForQuestionInPlaygroup(pid: self.playgroup.pid, qid: qid, userVote: userVoteInt)
        }
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
        guard let userInfo = notif.userInfo as? [String: Any], let shareLink = userInfo["shareLink"] as? String else {
            return
        }
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            if let socialController = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                logAnalyticsEvent(key: kEventOpenShareAnswer, params: ["answerLink": shareLink as NSObject])
                let url = URL(string: shareLink)
                socialController.add(url)
                self.present(socialController, animated: true, completion: {})
                socialController.completionHandler = { (result:SLComposeViewControllerResult) in
                    if result == SLComposeViewControllerResult.done {
                        logAnalyticsEvent(key: kEventSuccessShareAnswer, params: ["answerLink": shareLink as NSObject])
                    }
                }
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
    
    fileprivate let questionImg: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizesSubviews = true
        return imageView
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
        view.backgroundColor = UIColor.black
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
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        placeHolderVideo.isHidden = true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
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
    
    // MARK: Like and dislike container
    
    fileprivate func voteBtnTemplate(title: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitleColor(RED_UICOLOR, for: .normal)
        btn.setTitleColor(UIColor.white, for: .selected)
        btn.setBackgroundColor(color: UIColor.white, forState: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.setBackgroundColor(color: RED_UICOLOR, forState: .selected)
        btn.layer.borderColor = RED_UICOLOR.cgColor
        btn.layer.borderWidth = 0.8
        btn.layer.cornerRadius = 4.0
        btn.clipsToBounds = true
        return btn
    }
    
    fileprivate lazy var likeBtn: UIButton = {
        let btn = self.voteBtnTemplate(title: "Cool")
        btn.addTarget(self, action: #selector(voteBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    fileprivate lazy var dislikeBtn: UIButton = {
        let btn = self.voteBtnTemplate(title: "Boring")
        btn.addTarget(self, action: #selector(voteBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    func voteBtnPressed(btn: UIButton) {
        if btn == likeBtn {
            likeBtn.isSelected = !likeBtn.isSelected
            dislikeBtn.isSelected = false
        } else if btn == dislikeBtn {
            likeBtn.isSelected = false
            dislikeBtn.isSelected = !dislikeBtn.isSelected
        }
        
        // Store results locally
        if likeBtn.isSelected {
            question.userVote = .LIKED
        } else if dislikeBtn.isSelected {
            question.userVote = .DISLIKED
        } else {
            question.userVote = .NEUTRAL
        }
        
        // Post results to AnswersController to send to server
        NotificationCenter.default.post(name: NOTIF_VOTEANSWER, object: nil, userInfo: ["qid": question.qid, "userVote": question.userVote.rawValue])
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
        containerView.addSubview(questionImg)
        containerView.addSubview(questionText)
        containerView.addSubview(answerLbl)
        containerView.addSubview(answerVideo)
        containerView.addSubview(fbButton)
        
        let voteContainer = UIView()
        voteContainer.addSubview(likeBtn)
        voteContainer.addSubview(dislikeBtn)
        voteContainer.addConstraintsWithFormat("H:|[v0]-8-[v1]|", views: dislikeBtn, likeBtn)
        voteContainer.addConstraint(NSLayoutConstraint(item: dislikeBtn, attribute: .width, relatedBy: .equal, toItem: likeBtn, attribute: .width, multiplier: 1.0, constant: 0.0))
        voteContainer.addConstraintsWithFormat("V:|[v0]|", views: dislikeBtn)
        voteContainer.addConstraintsWithFormat("V:|[v0]|", views: likeBtn)
        containerView.addSubview(voteContainer)
        
        containerView.addConstraintsWithFormat("V:|-8-[v0(20)]-8-[v1(200)]-8-[v2]-8-[v3(20)]-8-[v4(250)]-8-[v5(40)]-8-[v6(40)]-8-|", views: questionLbl, questionImg, questionText, answerLbl, answerVideo, fbButton, voteContainer)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionImg)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerVideo)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: fbButton)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: voteContainer)
        
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
    
    fileprivate func loadImage() {
        let imageUrlString = self.question.imageName
        self.questionImg.af_cancelImageRequest()
        guard let imageUrl = URL(string: imageUrlString) else {
            self.questionImg.image = #imageLiteral(resourceName: "placeholder-image")
            return
        }
        
        self.questionImg.af_setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "placeholder-image"), filter: nil, progress: nil, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false, completion: { imageResponse in
            // Image finished downloading, so cache it - this is mostly for push notifications, as internally af_setImage already has its own cache
            if let imageData = imageResponse.data, let image = UIImage(data: imageData) {
                imageCache.add(image, withIdentifier: imageUrl.absoluteString)
            }
        })
    }
    
    func configureCell(questionObj: Question) {
        self.question = questionObj
        questionText.text = question.question
        
        // Download question image
        self.loadImage()
        
        // Load answer
        let answerLink: String = question.answer.trim() + "?&playsinline=1"
        self.answerVideo.stopLoading()
        let videoWidth = UIScreen.main.bounds.width - 8.0 * 4 // Double margin from outside cell and within cell
        let videoHeight = 250.0 // This matches the constraints defined above
        self.answerVideo.loadHTMLString("<iframe width=\"\(videoWidth)\" height=\"\(videoHeight)\" src=\"\(answerLink)\" frameborder=\"0\" allowfullscreen></iframe>", baseURL: nil)
        switch question.userVote {
        case .DISLIKED:
            dislikeBtn.isSelected = true
            likeBtn.isSelected = false
        case .NEUTRAL:
            dislikeBtn.isSelected = false
            likeBtn.isSelected = false
        case .LIKED:
            dislikeBtn.isSelected = false
            likeBtn.isSelected = true
        }
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
    
    fileprivate let questionImg: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizesSubviews = true
        return imageView
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
    
    // MARK: Like and dislike container
    
    fileprivate func voteBtnTemplate(title: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = FONT_HEAVY_LARGE
        btn.setTitleColor(RED_UICOLOR, for: .normal)
        btn.setTitleColor(UIColor.white, for: .selected)
        btn.setBackgroundColor(color: UIColor.white, forState: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.setBackgroundColor(color: RED_UICOLOR, forState: .selected)
        btn.layer.borderColor = RED_UICOLOR.cgColor
        btn.layer.borderWidth = 0.8
        btn.layer.cornerRadius = 4.0
        btn.clipsToBounds = true
        return btn
    }
    
    fileprivate lazy var likeBtn: UIButton = {
        let btn = self.voteBtnTemplate(title: "Cool")
        btn.addTarget(self, action: #selector(voteBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    fileprivate lazy var dislikeBtn: UIButton = {
        let btn = self.voteBtnTemplate(title: "Boring")
        btn.addTarget(self, action: #selector(voteBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    func voteBtnPressed(btn: UIButton) {
        if btn == likeBtn {
            likeBtn.isSelected = !likeBtn.isSelected
            dislikeBtn.isSelected = false
        } else if btn == dislikeBtn {
            likeBtn.isSelected = false
            dislikeBtn.isSelected = !dislikeBtn.isSelected
        }
        
        // Store results locally
        if likeBtn.isSelected {
            question.userVote = .LIKED
        } else if dislikeBtn.isSelected {
            question.userVote = .DISLIKED
        } else {
            question.userVote = .NEUTRAL
        }
        
        // Post results to AnswersController to send to server
        NotificationCenter.default.post(name: NOTIF_VOTEANSWER, object: nil, userInfo: ["qid": question.qid, "userVote": question.userVote.rawValue])
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
        containerView.addSubview(questionImg)
        containerView.addSubview(questionText)
        containerView.addSubview(answerLbl)
        containerView.addSubview(answerText)
        
        let voteContainer = UIView()
        voteContainer.addSubview(likeBtn)
        voteContainer.addSubview(dislikeBtn)
        voteContainer.addConstraintsWithFormat("H:|[v0]-8-[v1]|", views: dislikeBtn, likeBtn)
        voteContainer.addConstraint(NSLayoutConstraint(item: dislikeBtn, attribute: .width, relatedBy: .equal, toItem: likeBtn, attribute: .width, multiplier: 1.0, constant: 0.0))
        voteContainer.addConstraintsWithFormat("V:|[v0]|", views: dislikeBtn)
        voteContainer.addConstraintsWithFormat("V:|[v0]|", views: likeBtn)
        containerView.addSubview(voteContainer)
        
        containerView.addConstraintsWithFormat("V:|-8-[v0(20)]-8-[v1(200)]-8-[v2]-8-[v3(20)]-8-[v4]-8-[v5(40)]-8-|", views: questionLbl, questionImg, questionText,  answerLbl, answerText, voteContainer)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionImg)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerLbl)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: answerText)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: voteContainer)
        
        addSubview(containerView)
        addConstraintsWithFormat("H:|-12-[v0]-12-|", views: containerView)
        addConstraintsWithFormat("V:|-8-[v0]-8-|", views: containerView)
    }
    
    fileprivate func loadImage() {
        let imageUrlString = self.question.imageName
        self.questionImg.af_cancelImageRequest()
        guard let imageUrl = URL(string: imageUrlString) else {
            self.questionImg.image = #imageLiteral(resourceName: "placeholder-image")
            return
        }
        
        self.questionImg.af_setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "placeholder-image"), filter: nil, progress: nil, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false, completion: { imageResponse in
            // Image finished downloading, so cache it - this is mostly for push notifications, as internally af_setImage already has its own cache
            if let imageData = imageResponse.data, let image = UIImage(data: imageData) {
                imageCache.add(image, withIdentifier: imageUrl.absoluteString)
            }
        })
    }
    
    func configureCell(questionObj: Question) {
        self.question = questionObj
        self.loadImage()
        questionText.text = question.question
        answerText.text = question.answer
        switch question.userVote {
        case .DISLIKED:
            dislikeBtn.isSelected = true
            likeBtn.isSelected = false
        case .NEUTRAL:
            dislikeBtn.isSelected = false
            likeBtn.isSelected = false
        case .LIKED:
            dislikeBtn.isSelected = false
            likeBtn.isSelected = true
        }
    }
}
