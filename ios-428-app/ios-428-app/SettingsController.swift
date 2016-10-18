//
//  SettingsController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/17/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class SettingsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate let CELL_ID = "SETTING_CELL"
    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.frame, style: .grouped)
        tableView.backgroundColor = GRAY_UICOLOR
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingCell.self, forCellReuseIdentifier: self.CELL_ID)
        return tableView
    }()
    fileprivate var settingsChosen = [String: Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GRAY_UICOLOR
        populateData()
        self.navigationItem.title = "Settings"
        setupViews()
    }
    
    // MARK: Getting setting change and sending them to server
    
    func saveSettings() {
        // TODO: Send settings to server upon view disappearing
        for (k, v) in settingsChosen {
            log.info("\(k): \(v)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateEdit()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSettingsArr), name: NOTIF_CHANGESETTING, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NOTIF_CHANGESETTING, object: nil)
        self.saveSettings()
    }
    
    func updateSettingsArr(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: AnyObject], let option = userInfo["option"] as? String, let isOn = userInfo["isOn"] as? Bool {
            settingsChosen[option] = isOn
        }
    }
    
    // MARK: Set up views
    
    fileprivate lazy var myPicImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.layer.cornerRadius = 75.0
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.editProfile))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        return imageView
    }()
    
    // Used for animation of editButton
    fileprivate var editButtonHeightConstraint: NSLayoutConstraint!
    fileprivate var editButtonWidthConstraint: NSLayoutConstraint!
    
    fileprivate lazy var editButton: UIButton = {
        let button = UIButton()
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3.0
        button.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        button.setImage(#imageLiteral(resourceName: "edit"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(self.editProfile), for: .touchUpInside)
        return button
    }()
    
    fileprivate func animateEdit() {
        editButtonHeightConstraint.constant = 0.0
        editButtonWidthConstraint.constant = 0.0
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.18, animations: {
            self.editButtonHeightConstraint.constant = 40.0
            self.editButtonWidthConstraint.constant = 40.0
            self.view.layoutIfNeeded()
        }) { (completed) in
            UIView.animate(withDuration: 0.06, animations: {
                self.editButtonHeightConstraint.constant = 35.0
                self.editButtonWidthConstraint.constant = 35.0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // Grabs profile pic, and server settings for this user
    fileprivate func populateData() {
        self.myPicImageView.image = UIImage(named: "yihang-profile")
        self.settingsChosen = ["Daily connection": true, "Daily topic": true, "New connections": true, "Messages": true, "In-app vibrations": true]
    }
    
    fileprivate func setupViews() {
        let containerView = self.view!
        containerView.isUserInteractionEnabled = true
        containerView.backgroundColor = GRAY_UICOLOR
        // Add subviews
        containerView.addSubview(myPicImageView)
        containerView.addSubview(editButton)
        containerView.addSubview(tableView)
        
        // Apply constraints
        containerView.addConstraintsWithFormat("H:[v0(150)]", views: myPicImageView)
        containerView.addConstraint(NSLayoutConstraint(item: myPicImageView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: myPicImageView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        containerView.addConstraintsWithFormat("V:[v0(150)]-8-[v1]|", views: myPicImageView, tableView)
        
        // Edit button constraints manually set up this way so as to animate
        editButtonWidthConstraint = NSLayoutConstraint(item: editButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 35.0)
        editButtonHeightConstraint = NSLayoutConstraint(item: editButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 35.0)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addConstraint(editButtonWidthConstraint)
        editButton.addConstraint(editButtonHeightConstraint)
        
        containerView.addConstraint(NSLayoutConstraint(item: editButton, attribute: .right, relatedBy: .equal, toItem: myPicImageView, attribute: .right, multiplier: 1.0, constant: -10.0))
        containerView.addConstraint(NSLayoutConstraint(item: editButton, attribute: .bottom, relatedBy: .equal, toItem: myPicImageView, attribute: .bottom, multiplier: 1.0, constant: 0))
        
        containerView.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        
    }
    
    func editProfile() {
        log.info("Edit Profile")
    }
    
    // MARK: Table view
    
    fileprivate let settingHeaders: [String] = ["Discovery Settings", "Notifications", "Contact us", "Legal", "", ""]
    
    fileprivate let settings: [[Setting]] = [
        [Setting(text: "Daily connection", type: .toggle), Setting(text: "Daily topic", type: .toggle, isLastCell: true)],
        [Setting(text: "New connections", type: .toggle), Setting(text: "Messages", type: .toggle), Setting(text: "In-app vibrations", type: .toggle, isLastCell: true)],
        [Setting(text: "Help and Support", type: .link), Setting(text: "Rate us", type: .link), Setting(text: "Share 428", type: .link, isLastCell: true)],
        [Setting(text: "Privacy Policy", type: .link), Setting(text: "Terms", type: .link, isLastCell: true)],
        [Setting(text: "Log out", type: .center, isLastCell: true)],
        [Setting(text: "Version 1.0.0", type: .nobg, isLastCell: true)]]
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel(frame: CGRect(x: 8, y: 20, width: self.view.frame.width, height: 20))
        label.text = settingHeaders[section]
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.black
        view.addSubview(label)
        
        if section != settingHeaders.count - 1 { // Last section need not have divider
            let divider = UIView(frame: CGRect(x: 0, y: 45, width: self.view.frame.width, height: 0.5))
            divider.backgroundColor = UIColor(white: 0.5, alpha: 0.3)
            view.addSubview(divider)
        }
        
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingHeaders.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section != settingHeaders.count - 1) ? 45.5 : 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = settings[indexPath.section][indexPath.row]
        log.info("Selected row: \(setting.text)") // TODO: Perform right logic based on the selected row
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! SettingCell
        let setting = settings[indexPath.section][indexPath.row]
        cell.configureCell(settingObj: setting)
        return cell
    }
}
