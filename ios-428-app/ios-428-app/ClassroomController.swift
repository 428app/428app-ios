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

class ClassroomsController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
        collectionView.register(ClassroomCell.self, forCellWithReuseIdentifier: self.CELL_ID)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        self.view.backgroundColor = GRAY_UICOLOR
        self.navigationItem.title = "Classrooms"
        self.automaticallyAdjustsScrollViewInsets = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.loadData()
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        self.countdownTimer.invalidate()
    }
    
    // MARK: Firebase
    
    fileprivate func minAgo(minutesAgo: Double) -> Date {
        return Date().addingTimeInterval(-minutesAgo * 60.0)
    }
    
    fileprivate func loadClassrooms() -> [Classroom] {
        // TODO: Load classrooms from server
        
        // Create some dummy classrooms
        
        // Profiles
        let im1 = "https://scontent-sit4-1.xx.fbcdn.net/v/t1.0-9/12360259_1036119596431934_7410932159803664054_n.jpg?oh=84251aca7d9dcc8e428a9ee58c420f57&oe=58E36C07"
        let im2 = "https://scontent-sit4-1.xx.fbcdn.net/v/t1.0-9/15338895_214351679010971_9083811642954576817_n.jpg?oh=241c744be40dd57b91d00932d0879147&oe=58E1338E"
        let im3 = "https://scontent-sit4-1.xx.fbcdn.net/v/t31.0-8/13247840_10153651151013170_4586384765586065139_o.jpg?oh=2b8d422b5c0dda4734e77d180fd5392e&oe=58DAF753"
        let im4 = "https://scontent-sit4-1.xx.fbcdn.net/v/t1.0-9/12373224_10153942082375757_2547226759416788825_n.jpg?oh=801b6fb09dc2e9a7822ef09660955c75&oe=58E75959"
        
        let prof1 = Profile(uid: "1", name: "Leonard", profileImageName: im1, discipline: "Business", age: 25, location: "Singapore", school: "Harvard", org: "428", tagline: "Hey!", badges: [String](), classrooms: ["Physics"])
        let prof2 = Profile(uid: "2", name: "Tomas", profileImageName: im2, discipline: "Computer Science", age: 27, location: "Iceland", school: "Harvard", org: "Harvard", tagline: "Hey ya!", badges: [String](), classrooms: ["Physics"])
        let prof3 = Profile(uid: "3", name: "Jenny", profileImageName: im3, discipline: "Biology", age: 23, location: "USA", school: "Harvard", org: "428", tagline: "Hey!", badges: [String](), classrooms: ["Physics"])
        let prof4 = Profile(uid: "4", name: "Kyooeun", profileImageName: im4, discipline: "East Asian Studies", age: 25, location: "Korea", school: "Harvard", org: "428", tagline: "Hey!", badges: [String](), classrooms: ["Physics"])
        
        // Questions
        let q1 = Question(qid: "1", timestamp: 1, imageName: "https://scontent-sit4-1.xx.fbcdn.net/v/t31.0-8/15039689_1271173046259920_4366784399934560581_o.jpg?oh=22f4ffd1a592e2d0b55bf1208ca9e1d2&oe=58D6797C", question: "What happens when sperm travel to the speed of light? Think about it this way... what happens when anything travels to the speed of the light? Is it a black hole? Is it a plane? What is it?", answer: "Answer")
        let q2 = Question(qid: "2", timestamp: 2, imageName: "https://scontent-sit4-1.xx.fbcdn.net/v/t31.0-8/15068551_10155379098362506_9156974081960886025_o.jpg?oh=4c761407b791ca16541c2c237c2f414f&oe=58D869C7", question: "Q2", answer: "Answer")
        let q3 = Question(qid: "3", timestamp: 3, imageName: "https://scontent-sit4-1.xx.fbcdn.net/v/t1.0-9/14567998_10154822094095757_2510961597749082744_n.jpg?oh=95c0eb4a5f54fd8f4b02ec2f5dda2295&oe=58E6E644", question: "What happens when sperm travel to the speed of light? Think about it this way... what happens when anything travels to the speed of the light? Is it a black hole? Is it a plane? What is it?", answer: "Answer")
        let q4 = Question(qid: "4", timestamp: 4, imageName: "https://scontent-sit4-1.xx.fbcdn.net/v/t1.0-9/15326324_1298235190220372_4417723045154146576_n.jpg?oh=bcf6f25e81e8c5d0cbc7da11d3e87812&oe=58F2AD0F", question: "What happens when sperm travel to the speed of light? Think about it this way... what happens when anything travels to the speed of the light? Is it a black hole? Is it a plane? What is it?", answer: "Answer")
        let q5 = Question(qid: "5", timestamp: 5, imageName: "https://scontent-sit4-1.xx.fbcdn.net/v/t1.0-9/15326324_1298235190220372_4417723045154146576_n.jpg?oh=bcf6f25e81e8c5d0cbc7da11d3e87812&oe=58F2AD0F", question: "What happens when sperm travel to the speed of light? Think about it this way... what happens when anything travels to the speed of the light? Is it a black hole? Is it a plane? What is it?", answer: "What happens when sperm travel to the speed of light? Think about it this way... what happens when anything travels to the speed of the light? Is it a black hole? Is it a plane? What is it?")
        
        // Messages
        let m1 = ClassroomMessage(mid: "1", parentCid: "1", posterUid: "1", posterImageName: im1, posterName: "Leonard", text: "Sup guys!", date: minAgo(minutesAgo: 10), isSentByYou: false)
        let m2 = ClassroomMessage(mid: "1", parentCid: "1", posterUid: "2", posterImageName: im2, posterName: "Tomas", text: "What happens when sperm travel to the speed of light? Think about it this way... what happens when anything travels to the speed of the light? Is it a black hole? Is it a plane? What is it?", date: minAgo(minutesAgo: 8), isSentByYou: false)
        let m3 = ClassroomMessage(mid: "1", parentCid: "1", posterUid: "3", posterImageName: im3, posterName: "Jenny", text: "Hahaha!", date: minAgo(minutesAgo: 6), isSentByYou: false)
        let m4 = ClassroomMessage(mid: "1", parentCid: "1", posterUid: "5", posterImageName: im1, posterName: "Yihang", text: "That is lame.", date: minAgo(minutesAgo: 4), isSentByYou: true)
        let m5 = ClassroomMessage(mid: "1", parentCid: "1", posterUid: "4", posterImageName: im4, posterName: "Kyooeun", text: "Oh this is lively isn't it! :)", date: minAgo(minutesAgo: 2), isSentByYou: false)
        
        let messages = [m1, m2, m3, m4, m5]
        
        let room1 = Classroom(cid: "1", title: "Physics", timeCreated: 1, members: [prof1, prof2, prof3, prof4], questions: [q1, q2, q3, q4, q5], classroomMessages: messages, hasSeen: true)
        
        let room2 = Classroom(cid: "2", title: "Business", timeCreated: 2, members: [prof1, prof2, prof3, prof4], questions: [q1])
        let room3 = Classroom(cid: "3", title: "Computer Science", timeCreated: 3, members: [prof1, prof2, prof3, prof4], questions: [q3, q4])
        
        var rooms = [room1, room2, room3]
        
        // Sort rooms by most recent one first
        rooms = rooms.sorted{$0.timeCreated > $1.timeCreated}
        
        return rooms
    }
    
    fileprivate func loadData() {
        self.classrooms = loadClassrooms()
        if self.classrooms.count == 0 {
            emptyPlaceholderView.isHidden = false
            self.countdownTimer.invalidate()
            self.countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
            self.countdownTimer.fire()
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
    }
    
    // MARK: Collection view of classrooms
    
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
        return CGSize(width: view.frame.width, height: 262.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let classroom = classrooms[indexPath.row]
        log.info("Selected classroom: \(classroom.title)")
        let controller = ChatClassroomController()
        controller.classroom = classroom
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
}
