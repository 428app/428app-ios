//
//  ChatHeaderView.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ChatHeaderView: UICollectionReusableView {
    
    var date: Date! {
        didSet {
            timeLabel.text = formatDateToText(date: self.date)
        }
    }
    
    var timeLabel: UILabel = {
       let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 12.0)
        label.font = UIFont.boldSystemFont(ofSize: 12.0)
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        addSubview(timeLabel)
        addConstraintsWithFormat("H:|[v0]|", views: timeLabel)
        addConstraintsWithFormat("V:|[v0]|", views: timeLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func formatDateToText(date: Date) -> String {
        var text = ""
        let dateFormatter = DateFormatter()
        let elapsedTimeInSeconds = Date().timeIntervalSince(date as Date)
        let secondInDays: TimeInterval = 60 * 60 * 24
        if elapsedTimeInSeconds > 7 * secondInDays { // More than 7 days ago
            dateFormatter.dateFormat = "d MMM yyyy, h:mm a"
            text = dateFormatter.string(from: date as Date)
        } else if elapsedTimeInSeconds >= 1 * secondInDays { // 2 - 7 days ago
            dateFormatter.dateFormat = "EEE h:mm a"
            text = dateFormatter.string(from: date as Date)
        } else { // Today
            dateFormatter.dateFormat = "h:mm a"
            text = dateFormatter.string(from: date as Date)
        }
        return text
    }

}
