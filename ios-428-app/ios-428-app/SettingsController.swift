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
    
    fileprivate let CELL_ID = "settingCell"
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
    
    
    fileprivate func setSettingTableBasedOnText(option: String, isOn: Bool) {
        switch option {
        case "Daily alert":
            self.settings[0][0].isOn = isOn
        case "Private messages":
            self.settings[0][1].isOn = isOn
        case "Classroom messages":
            self.settings[0][2].isOn = isOn
        case "In-app notifications":
            self.settings[0][3].isOn = isOn
        default:
            return
        }
    }
    
    fileprivate var settingsChosen: [String: Bool]! {
        didSet {
            // Once set, reload table
            for (option, isOn) in settingsChosen {
                setSettingTableBasedOnText(option: option, isOn: isOn)
            }
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GRAY_UICOLOR
        self.navigationItem.title = "Settings"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUserSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSettingsArr), name: NOTIF_CHANGESETTING, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NOTIF_CHANGESETTING, object: nil)
    }
    
    // Settings are updated to server upon every toggle
    func updateSettingsArr(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: AnyObject], let option = userInfo["option"] as? String, let isOn = userInfo["isOn"] as? Bool {
            
            self.settingsChosen[option] = isOn
            
            // Update all user settings with each change
            
            DataService.ds.updateUserSettings(dailyAlert: settingsChosen["Daily alert"]!, inboxMessages: settingsChosen["Private messages"]!, classroomMessages: settingsChosen["Classroom messages"]!, inAppNotifications: settingsChosen["In-app notifications"]!, completed: { (isSuccess) in
                if !isSuccess {
                    log.error("[Error] Error updating user settings")
                    // Revert settings chosen
                    self.settingsChosen[option] = !isOn
                    self.setSettingTableBasedOnText(option: option, isOn: !isOn)
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    // MARK: Firebase
    
    fileprivate func getUserSettings() {
        // Load default settings first - All enabled
        self.settingsChosen = ["Daily alert": true, "Private messages": true, "Classroom messages": true, "In-app notifications": true]
        
        DataService.ds.getUserSettings(completed: { (settings) in
            if settings != nil {
                self.settingsChosen = settings!
            }
        })
    }
    
    // MARK: Set up views
    
    fileprivate func setupViews() {
        self.view.backgroundColor = GRAY_UICOLOR
        self.view.addSubview(tableView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        self.view.addConstraintsWithFormat("V:|[v0]|", views: tableView)
    }
    
    // MARK: Table view
    
    // Note: The setting headers have to match with the 2d array settings. The number of entries in setting headers has to be the same as the number of setting arrays in settings.
    
    fileprivate var settingHeaders: [String] = ["Notifications", "Find us", "Legal", "", ""]
    
    fileprivate var settings: [[Setting]] = [
        [Setting(text: "Daily alert", type: .toggle, isOn: true),  Setting(text: "Private messages", type: .toggle, isOn: true), Setting(text: "Classroom messages", type: .toggle, isOn: true), Setting(text: "In-app notifications", type: .toggle, isLastCell: true, isOn: true)],
        [Setting(text: "428 Website", type: .link), Setting(text: "428 Facebook", type: .link), Setting(text: "Rate us", type: .link, isLastCell: true)],
        [Setting(text: "Privacy Policy", type: .link, isLastCell: true)],
        [Setting(text: "Log out", type: .center, isLastCell: true)],
        [Setting(text: "Version 1.0.0", type: .nobg, isLastCell: true)]]
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel(frame: CGRect(x: 16, y: 20, width: self.view.frame.width, height: 20))
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
        // Last section does not have divider so have different height
        return (section != settingHeaders.count - 1) ? 45.5 : 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = settings[indexPath.section][indexPath.row]
        if setting.text == "Log out" {
            self.logout()
        } else if setting.text == "428 Website" {
            logAnalyticsEvent(key: kEventVisitWebsite)
            let controller = WebviewController()
            controller.urlString = "https://www.428pm.com"
            self.navigationItem.backBarButtonItem?.title = "Back to 428"
            self.navigationController?.pushViewController(controller, animated: true)
        } else if setting.text == "428 Facebook" {
            logAnalyticsEvent(key: kEventVisitFacebook)
            let controller = WebviewController()
            controller.urlString = "https://www.facebook.com/428app"
            self.navigationItem.backBarButtonItem?.title = "Back to 428"
            self.navigationController?.pushViewController(controller, animated: true)
        } else if setting.text == "Rate us" {
            // TODO: Add rate link
            logAnalyticsEvent(key: kEventRateUs)
            
        } else if setting.text == "Privacy Policy" {
            logAnalyticsEvent(key: kEventVisitPrivacyPolicy)
            let controller = WebviewController()
            controller.urlString = "https://www.428pm.com/?open=terms-and-conditions"
            self.navigationItem.backBarButtonItem?.title = "Back to 428"
            self.navigationController?.pushViewController(controller, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func logout() {
        let alertController = UIAlertController(title: "Are you sure?", message: "You will not be notified of all the juicy questions and fun conversation!", preferredStyle: .actionSheet)
        alertController.view.tintColor = GREEN_UICOLOR
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let logoutAction = UIAlertAction(title: "Log out", style: .default) { (action) in
            showLoader(message: "Logging you out...")
            DataService.ds.logout(completed: { (isSuccess) in
                hideLoader()
                if isSuccess {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    log.error("[Error] Could not log user out")
                    showErrorAlert(vc: self, title: "Could not log out", message: "We apologize. We could not log you out for now. Please try again later.")
                }
            })
        }
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: {
            alertController.view.tintColor = GREEN_UICOLOR
        })
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // If last section, taller height because of image
        if indexPath.row == settings.count - 1 {
            return 140.0
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
