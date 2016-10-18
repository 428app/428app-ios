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
        label.font = FONT_MEDIUM_MID
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        return label
    }()
    
    fileprivate let dividerView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.3)
        return view
    }()
    
    override func setupViews() {
        
        super.setupViews()
        addSubview(settingLabel)
        addSubview(dividerView)
        addConstraintsWithFormat("H:|-8-[v0]-8-|", views: settingLabel)
        addConstraintsWithFormat("V:|-8-[v0(30)]", views: settingLabel)
        addConstraintsWithFormat("V:[v0(0.5)]|", views: dividerView)
        
        
    }
    
    func configureCell(settingObj: Setting) {
        self.setting = settingObj
        settingLabel.text = setting.text
        if setting.type == .link {
            // Handle link
        } else {
            // Handle type
        }
        
        if setting.isLastCell {
            // Span the whole divider view
            addConstraintsWithFormat("H:|[v0]|", views: dividerView)
        } else {
            addConstraintsWithFormat("H:|-16-[v0]|", views: dividerView)
        }
        
    }

}
