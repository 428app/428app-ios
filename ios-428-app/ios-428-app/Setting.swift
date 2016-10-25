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
        case toggle = 0, link, center, nobg, profilepic, timer
    }
    
    fileprivate var _text: String // Can be text or url for profilepic
    fileprivate var _type: Setting.TYPE
    fileprivate var _isLastCell: Bool
    fileprivate var _image: UIImage?
    
    init(text: String, type: Setting.TYPE, image: UIImage? = nil, isLastCell: Bool = false) {
        _text = text
        _type = type
        _image = image
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
    
    var image: UIImage? {
        get {
            return _image
        }
        set (image) {
            _image = image
        }
    }
    
    var isLastCell: Bool {
        get {
            return _isLastCell
        }
    }
}
