
//
//  RoundImageView.swift
//  ios-428
//
//  Created by Leonard Loo on 10/6/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {

    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.width / 2.0
        self.layer.masksToBounds = true
        self.clipsToBounds = true
    }

}
