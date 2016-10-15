//
//  Extensions.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        _ = _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    func addAndGetConstraintsWithFormat(_ format: String, views: UIView...) -> [NSLayoutConstraint] {
        return _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    fileprivate func _addAndGetConstraintsWithFormat(_ format: String, views: [UIView]) -> [NSLayoutConstraint] {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        let constraints_ = NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary)
        addConstraints(constraints_)
        return constraints_
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
}
