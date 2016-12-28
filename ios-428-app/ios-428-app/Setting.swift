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
import UIKit

class Setting {
    
    enum TYPE: Int {
        case toggle = 0, link, center, nobg
    }
    
    fileprivate var _text: String // Can be text or url for profilepic
    fileprivate var _type: Setting.TYPE
    fileprivate var _isOn: Bool? // Used only by toggle type, otherwise nil
    fileprivate var _isLastCell: Bool
    
    init(text: String, type: Setting.TYPE, isLastCell: Bool = false, isOn: Bool? = nil) {
        _text = text
        _type = type
        _isLastCell = isLastCell
        _isOn = isOn
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
    
    var isOn: Bool? {
        get {
            return _isOn
        }
        set(on) {
            _isOn = on
        }
    }
}
