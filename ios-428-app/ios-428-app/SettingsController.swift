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
    
    
    fileprivate func setSettingTableBasedOnText(option: String, isOn: Bool) {
        switch option {
        case "New connections":
            self.settings[2][0].isOn = isOn
        case "New topics":
            self.settings[2][1].isOn = isOn
        case "Daily alert":
            self.settings[3][0].isOn = isOn
        case "Connection messages":
            self.settings[3][1].isOn = isOn
        case "Topic messages":
            self.settings[3][2].isOn = isOn
        case "In-app notifications":
            self.settings[3][3].isOn = isOn
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
            
//            self.settings[2][0].isOn = self.settingsChosen["New connections"]
//            self.settings[2][1].isOn = self.settingsChosen["New topics"]
//            self.settings[3][0].isOn = self.settingsChosen["Daily alert"]
//            self.settings[3][1].isOn = self.settingsChosen["Connection messages"]
//            self.settings[3][2].isOn = self.settingsChosen["Topic messages"]
//            self.settings[3][3].isOn = self.settingsChosen["In-app notifications"]
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GRAY_UICOLOR
        populateData()
        self.navigationItem.title = "Settings"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Always load image from MyProfile.swift upon entering because EditProfileController might have uploaded new image
        loadImage()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSettingsArr), name: NOTIF_CHANGESETTING, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openEditProfile), name: NOTIF_EDITPROFILE, object: nil)
    }
    
    fileprivate var cameFromViewDidLoad = true // Prevents table view from being reloaded twice on first entering
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !cameFromViewDidLoad {
            tableView.reloadData()
        } else {
            cameFromViewDidLoad = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timerForCountdown.invalidate()
        NotificationCenter.default.removeObserver(self, name: NOTIF_CHANGESETTING, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIF_EDITPROFILE, object: nil)
    }
    
    
    // Settings are updated to server upon every toggle
    func updateSettingsArr(notif: Notification) {
        if let userInfo = notif.userInfo as? [String: AnyObject], let option = userInfo["option"] as? String, let isOn = userInfo["isOn"] as? Bool {
            self.settingsChosen[option] = isOn
            
            DataService.ds.updateUserSettings(newConnections: settingsChosen["New connections"]!, newTopics: settingsChosen["New topics"]!, dailyAlert: settingsChosen["Daily alert"]!, connectionMessages: settingsChosen["Connection messages"]!, topicMessages: settingsChosen["Topic messages"]!, inAppNotifications: settingsChosen["In-app notifications"]!, completed: { (isSuccess) in
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
    
    func openEditProfile(notif: Notification) {
        let controller = EditProfileController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: Set up views
    
    func loadImage() {
        // Change Setting cell's image upon getting a change
        var imageUsed = UIImage(color: UIColor.white)
        if let profileImage = myProfilePhoto {
            imageUsed = profileImage
        }
        self.settings[1][0].image = imageUsed
        self.tableView.reloadData()
    }
    
    // Grabs server settings, user profile from Firebase, then downloads profile image
    fileprivate func populateData() {
        NewDataService.ds.getUserFields(uid: getStoredUid()) { (isSuccess, profile) in
            if isSuccess && profile != nil {
                myProfile = profile
                NotificationCenter.default.post(name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
                
                // Downloads profile photo, or get from uploaded pic that previously failed
                myProfilePhoto = getPhotoToUpload(isProfilePic: true)
                if myProfilePhoto != nil {
                    // Retry upload of image
                    self.settings[1][0].image = myProfilePhoto!
                    self.tableView.reloadData()
                    if let imageData = UIImageJPEGRepresentation(myProfilePhoto!, 1.0) {
                        StorageService.ss.uploadOwnPic(data: imageData, completed: { (isSuccess) in
                            if !isSuccess {
                                log.error("[Error] Unable to upload profile pic to storage")
                            } else {
                                // Upload success, delete cached profile photo
                                cachePhotoToUpload(data: nil)
                            }
                        })
                    }
                } else {
                    // Download image
                    _ = downloadImage(imageUrlString: profile!.profileImageName, completed: { (image) in
                        if image != nil {
                            self.settings[1][0].image = image
                            self.tableView.reloadData()
                            myProfilePhoto = image!
                            NotificationCenter.default.post(name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
                        }
                    })
                }
                
                // Do the same for cover photo
                myCoverPhoto = getPhotoToUpload(isProfilePic: false)
                if myCoverPhoto != nil {
                    // Retry upload of image
                    if let imageData = UIImageJPEGRepresentation(myCoverPhoto!, 1.0) {
                        StorageService.ss.uploadOwnPic(data: imageData, completed: { (isSuccess) in
                            if !isSuccess {
                                log.error("[Error] Unable to upload cover pic to storage")
                            } else {
                                // Upload success, delete cache
                                cachePhotoToUpload(data: nil)
                            }
                        })
                    }
                } else {
                    // Download image
//                    _ = downloadImage(imageUrlString: profile!.coverImageName, completed: { (image) in
//                        if image != nil {
//                            myCoverPhoto = image!
//                            NotificationCenter.default.post(name: NOTIF_MYPROFILEDOWNLOADED, object: nil)
//                        }
//                    })
                }
            }
        }
        
        // Load default settings first - All enabled
        self.settingsChosen = ["New connections": true, "New topics": true, "Daily alert": true, "Connection messages": true, "Topic messages": true, "In-app notifications": true]
        
        DataService.ds.getUserSettings(completed: { (settings) in
            if settings != nil {
                self.settingsChosen = settings!
            }
        })
    }
    
    fileprivate func setupViews() {
        self.view.backgroundColor = GRAY_UICOLOR
        self.view.addSubview(tableView)
        self.view.addConstraintsWithFormat("H:|[v0]|", views: tableView)
        self.view.addConstraintsWithFormat("V:|[v0]|", views: tableView)
    }
    
    // MARK: Table view
    
    fileprivate var settingHeaders: [String] = ["", "", "Discovery Settings", "Notifications", "Contact and Share", "Legal", "", ""]
    
    fileprivate var settings: [[Setting]] = [
        [Setting(text: "", type: .timer)],
        [Setting(text: "", type: .profilepic, image: UIImage(color: UIColor.white))],
        [Setting(text: "New connections", type: .toggle, isOn: true), Setting(text: "New topics", type: .toggle, isLastCell: true, isOn: true)],
        [Setting(text: "Daily alert", type: .toggle, isOn: true),  Setting(text: "Connection messages", type: .toggle, isOn: true), Setting(text: "Topic messages", type: .toggle, isOn: true), Setting(text: "In-app notifications", type: .toggle, isLastCell: true, isOn: true)],
        [Setting(text: "Help and Support", type: .link), Setting(text: "Rate us", type: .link), Setting(text: "Share 428", type: .link, isLastCell: true)],
        [Setting(text: "Privacy Policy", type: .link), Setting(text: "Terms", type: .link, isLastCell: true)],
        [Setting(text: "Log out", type: .center, isLastCell: true)],
        [Setting(text: "Version 1.0.0", type: .nobg, isLastCell: true)]]
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section <= 1 { // No section header for timer and profile pic
            return nil
        }
        
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
        if section == 0 {
            return 18.0
        }
        if section == 1 {
            return 0.001
        }
        return (section != settingHeaders.count - 1) ? 45.5 : 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = settings[indexPath.section][indexPath.row]
        log.info("Selected row: \(setting.text)") // TODO: Perform right logic based on the selected row
        if setting.text == "Log out" {
            self.logout()
        }
    }
    
    fileprivate func logout() {
        let alertController = UIAlertController(title: "Are you sure?", message: "You will not be notified of your daily connections and topics!", preferredStyle: .actionSheet)
        alertController.view.tintColor = GREEN_UICOLOR
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let logoutAction = UIAlertAction(title: "Log out", style: .default) { (action) in
            showLoader(message: "Logging you out...")
            NewDataService.ds.logout(completed: { (isSuccess) in
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
        self.present(alertController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 { // Extra height for profilepic
            return 170.0
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
