//
//  SettingCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/17/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class SettingCell: BaseTableViewCell {
    
    fileprivate var setting: Setting!
    
    fileprivate let settingLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_LARGE
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let dividerView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.3)
        return view
    }()
    
    // MARK: Switch
    
    fileprivate lazy var optionSwitch: UISwitch = {
        var switch_ = UISwitch()
        switch_.isOn = true // Read this from server
        switch_.addTarget(self, action: #selector(switchValueDidChange), for: .valueChanged)
        switch_.tintColor = GREEN_UICOLOR
        return switch_
    }()
    
    func switchValueDidChange(switch_: UISwitch) {
        log.info("\(self.setting.text) switch changed to \(switch_.isOn)")
        NotificationCenter.default.post(name: NOTIF_CHANGESETTING, object: nil, userInfo: ["option": setting.text, "isOn": switch_.isOn])
    }
    
    // MARK: Profile pic
    
    fileprivate lazy var myPicImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 85.0
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.editProfile))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        return imageView
    }()
    
    fileprivate lazy var editButton: UIButton = {
        let button = UIButton()
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3.0
        button.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        button.setImage(#imageLiteral(resourceName: "edit"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(self.editProfile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    func editProfile() {
        NotificationCenter.default.post(name: NOTIF_EDITPROFILE, object: nil)
    }

    fileprivate func animateEdit() {
        UIView.animate(withDuration: 0.3, animations: {
            self.editButton.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            }) { (completion) in
                UIView.animate(withDuration: 0.12, animations: {
                    self.editButton.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                })
        }
    }
    
    // MARK: Timer
    
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
    
    fileprivate let timerLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let timerDetailLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .center
        label.text = "until 4:28pm"
        return label
    }()
    
    // MARK: Set up views
    
    override func setupViews() {
        super.setupViews()
        addSubview(settingLabel)
        addSubview(dividerView)
        addConstraintsWithFormat("V:[v0(30)]", views: settingLabel)
        addConstraint(NSLayoutConstraint(item: settingLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
        addConstraintsWithFormat("V:[v0(0.5)]|", views: dividerView)
    }
    
    fileprivate var constraintsToDelete: [NSLayoutConstraint] = [NSLayoutConstraint]()
    fileprivate var viewsToRemove: [UIView] = [UIView]()
    
    fileprivate func resetAll() {
        for v in viewsToRemove {
            v.removeFromSuperview()
        }
        for const in constraintsToDelete {
            removeConstraint(const)
        }
        self.accessoryType = .none
        self.selectionStyle = .none
        backgroundColor = UIColor.white
        dividerView.isHidden = false
        settingLabel.font = FONT_MEDIUM_LARGE
        settingLabel.isHidden = false
    }
    
    func configureCell(settingObj: Setting) {
        self.setting = settingObj
        settingLabel.text = setting.text
        
        resetAll()
        
        if setting.type == .link {
            
            // Link to website / function
            
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|-16-[v0]", views: settingLabel))
            self.selectionStyle = .gray
            self.accessoryType = .disclosureIndicator
            
        } else if setting.type == .toggle {
            
            // Handle toggle by appending switch
            
            addSubview(optionSwitch)
            viewsToRemove.append(optionSwitch)
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|-16-[v0]", views: settingLabel))
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:[v0]-16-|", views: optionSwitch))
            let centerYswitchConstraint = NSLayoutConstraint(item: optionSwitch, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
            self.addConstraint(centerYswitchConstraint)
            constraintsToDelete.append(centerYswitchConstraint)
        } else if setting.type == .center {
            
            // Used by Log out
            
            self.selectionStyle = .gray
            let centerXSettingConstraint = NSLayoutConstraint(item: settingLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
            self.addConstraint(centerXSettingConstraint)
            constraintsToDelete.append(centerXSettingConstraint)
        } else if setting.type == .nobg {
            
            // Used to display Version number at bottom
            
            backgroundColor = GRAY_UICOLOR
            let centerXSettingConstraint = NSLayoutConstraint(item: settingLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
            self.addConstraint(centerXSettingConstraint)
            constraintsToDelete.append(centerXSettingConstraint)
            dividerView.isHidden = true
            settingLabel.font = FONT_HEAVY_MID
        } else if setting.type == .profilepic {
            
            // Used to display profile pic on top

            backgroundColor = GRAY_UICOLOR
            myPicImageView.image = UIImage(named: setting.text)
            addSubview(myPicImageView)
            addSubview(editButton)
            viewsToRemove.append(myPicImageView)
            viewsToRemove.append(editButton)
            settingLabel.isHidden = true
            dividerView.isHidden = true
            
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:[v0(170)]", views: myPicImageView))
            let centerXPicConstraint = NSLayoutConstraint(item: myPicImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
            addConstraint(centerXPicConstraint)
            constraintsToDelete.append(centerXPicConstraint)
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("V:[v0(170)]|", views: myPicImageView))
            
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("V:[v0(25.0)]", views: editButton))
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:[v0(25.0)]", views: editButton))
            let editButtonRightConstraint = NSLayoutConstraint(item: editButton, attribute: .right, relatedBy: .equal, toItem: myPicImageView, attribute: .right, multiplier: 1.0, constant: -10.0)
            addConstraint(editButtonRightConstraint)
            constraintsToDelete.append(editButtonRightConstraint)
            let editButtonBottomConstraint = NSLayoutConstraint(item: editButton, attribute: .bottom, relatedBy: .equal, toItem: myPicImageView, attribute: .bottom, multiplier: 1.0, constant: 0)
            addConstraint(editButtonBottomConstraint)
            constraintsToDelete.append(editButtonBottomConstraint)
            
            animateEdit()
        
        } else if setting.type == .timer {
            
            // Used to display timer at the top
            
            addSubview(timerLabel)
            addSubview(timerDetailLabel)
            viewsToRemove.append(timerLabel)
            viewsToRemove.append(timerDetailLabel)
            timerForCountdown.invalidate()
            timerForCountdown = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
            timerForCountdown.fire()
            settingLabel.isHidden = true
            dividerView.isHidden = true
            backgroundColor = GRAY_UICOLOR
            
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|[v0]|", views: timerLabel))
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|[v0]|", views: timerDetailLabel))
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("V:[v0(25)]-2-[v1(20)]", views: timerLabel, timerDetailLabel))
        }
        
        if setting.isLastCell {
            // Span the whole divider view if it is the last cell
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|[v0]|", views: dividerView))
        } else {
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|-16-[v0]|", views: dividerView))
        }
    }
}
