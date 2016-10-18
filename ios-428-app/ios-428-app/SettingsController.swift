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
        tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSettingsArr), name: NOTIF_CHANGESETTING, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openEditProfile), name: NOTIF_EDITPROFILE, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NOTIF_CHANGESETTING, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_EDITPROFILE, object: nil)
        self.saveSettings()
    }
    
    func updateSettingsArr(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: AnyObject], let option = userInfo["option"] as? String, let isOn = userInfo["isOn"] as? Bool {
            settingsChosen[option] = isOn
        }
    }
    
    func openEditProfile(notif: Notification) {
        log.info("Open edit profile")
    }
    
    // MARK: Set up views
    
    // Grabs profile pic, and server settings for this user
    fileprivate func populateData() {
        self.settings.insert([Setting(text: "yihang-profile", type: .profilepic)], at: 0)
        self.settingsChosen = ["Daily connection": true, "Daily topic": true, "New connections": true, "Messages": true, "In-app vibrations": true]
    }
    
    fileprivate func setupViews() {
        self.view.backgroundColor = GRAY_UICOLOR
        self.view.addSubview(tableView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        self.view.addConstraintsWithFormat("V:|[v0]|", views: tableView)
    }
    
    // MARK: Table view
    
    fileprivate let settingHeaders: [String] = ["", "Discovery Settings", "Notifications", "Contact us", "Legal", "", ""]
    
    fileprivate var settings: [[Setting]] = [
        [Setting(text: "Daily connection", type: .toggle), Setting(text: "Daily topic", type: .toggle, isLastCell: true)],
        [Setting(text: "New connections", type: .toggle), Setting(text: "Messages", type: .toggle), Setting(text: "In-app vibrations", type: .toggle, isLastCell: true)],
        [Setting(text: "Help and Support", type: .link), Setting(text: "Rate us", type: .link), Setting(text: "Share 428", type: .link, isLastCell: true)],
        [Setting(text: "Privacy Policy", type: .link), Setting(text: "Terms", type: .link, isLastCell: true)],
        [Setting(text: "Log out", type: .center, isLastCell: true)],
        [Setting(text: "Version 1.0.0", type: .nobg, isLastCell: true)]]
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { // No section header for profile pic
            return nil
        }
        
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
        if section == 0 {
            return 0
        }
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
        if indexPath.section == 0 {
            return 150.0
        }
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! SettingCell
        let setting = settings[indexPath.section][indexPath.row]
        cell.configureCell(settingObj: setting)
        return cell
    }
}
