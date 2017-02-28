//
//  PlaygroupQuestionCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 2/25/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation
import UIKit

class PlaygroupQuestionCell: BaseCollectionCell {
    
    fileprivate var message: PlaygroupMessage!
    open var shouldExpand = false
    
    fileprivate let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = RED_UICOLOR
        return view
    }()
    
    fileprivate let questionLbl: UILabel = {
       let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override func setupViews() {
        super.setupViews()
        addSubview(bgView)
        bgView.addSubview(questionLbl)
        addConstraintsWithFormat("H:|[v0]|", views: bgView)
        addConstraintsWithFormat("V:|[v0]|", views: bgView)
        bgView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionLbl)
        bgView.addConstraintsWithFormat("V:|-8-[v0]-8-|", views: questionLbl)
        let tap = UITapGestureRecognizer(target: self, action: #selector(animateBGColor))
        questionLbl.addGestureRecognizer(tap)
    }
    
    func configureCell(messageObj: PlaygroupMessage) {
        self.message = messageObj
        
        // Attributed string to increase spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let str = NSMutableAttributedString(string: self.message.text, attributes: [NSForegroundColorAttributeName: UIColor.white, NSParagraphStyleAttributeName: paragraphStyle])
        self.questionLbl.attributedText = str
    }
    
    func animateBGColor(gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3, animations: { 
            self.bgView.backgroundColor = GREEN_UICOLOR
        }) { (isSuccess) in
            UIView.animate(withDuration: 0.3, animations: { 
                self.bgView.backgroundColor = RED_UICOLOR
            }, completion: { (isSuccess) in
                UIView.animate(withDuration: 0.3, animations: { 
                    self.bgView.backgroundColor = GREEN_UICOLOR
                }, completion: { (isSuccess) in
                    UIView.animate(withDuration: 0.3, animations: { 
                        self.bgView.backgroundColor = RED_UICOLOR
                    }, completion: nil)
                })
            })
        }
    }
}
