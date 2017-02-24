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
    
    fileprivate let versionLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_LARGE
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let logo428: UIImageView = {
        let logo = #imageLiteral(resourceName: "logo")
        let imageView = UIImageView(image: logo)
        imageView.contentMode = .scaleAspectFit
        return imageView
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
        NotificationCenter.default.post(name: NOTIF_CHANGESETTING, object: nil, userInfo: ["option": setting.text, "isOn": switch_.isOn])
    }
    
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
            
            // Link to website, Facebook or rate us
            
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|-16-[v0]", views: settingLabel))
            self.selectionStyle = .gray
            self.accessoryType = .disclosureIndicator
            
        } else if setting.type == .toggle {
            
            // Handle toggle by appending switch
            
            if setting.isOn != nil {
                optionSwitch.isOn = setting.isOn!
            }
            
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
            
            // Used to display logo and version number at bottom
            
            settingLabel.isHidden = true
            versionLabel.text = setting.text
            
            let centralizedView = UIView()
            centralizedView.addSubview(logo428)
            centralizedView.addSubview(versionLabel)
            centralizedView.addConstraintsWithFormat("H:[v0(60)]", views: logo428)
            centralizedView.addConstraint(NSLayoutConstraint(item: logo428, attribute: .centerX, relatedBy: .equal, toItem: centralizedView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            centralizedView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: versionLabel)
            centralizedView.addConstraintsWithFormat("V:|-8-[v0(60)]-8-[v1(30)]-8-|", views: logo428, versionLabel)
            
            addSubview(centralizedView)
            viewsToRemove.append(centralizedView)
            
            backgroundColor = GRAY_UICOLOR
            let centerYConstraint = NSLayoutConstraint(item: centralizedView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
            self.addConstraint(centerYConstraint)
            constraintsToDelete.append(centerYConstraint)
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|-8-[v0]-8-|", views: centralizedView))
            dividerView.isHidden = true
            
        }
        
        if setting.isLastCell {
            // Span the whole divider view if it is the last cell
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|[v0]|", views: dividerView))
        } else {
            constraintsToDelete.append(contentsOf: addAndGetConstraintsWithFormat("H:|-16-[v0]|", views: dividerView))
        }
    }
}
