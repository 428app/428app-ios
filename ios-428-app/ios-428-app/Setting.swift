//
//  Setting.swift
//  ios-428-app
//
//  Used for SettingCell in SettingsController
//
//  Created by Leonard Loo on 10/17/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

class Setting {
    
    enum TYPE: Int {
        case toggle = 0, link, center, nobg
    }
    
    fileprivate var _text: String
    fileprivate var _type: Setting.TYPE
    fileprivate var _isLastCell: Bool
    
    init(text: String, type: Setting.TYPE, isLastCell: Bool = false) {
        _text = text
        _type = type
        _isLastCell = isLastCell
    }
    
    var text: String {
        get {
            return _text
        }
    }
    
    var type: Setting.TYPE {
        get {
            return _type
        }
    }
    
    var isLastCell: Bool {
        get {
            return _isLastCell
        }
    }
}
