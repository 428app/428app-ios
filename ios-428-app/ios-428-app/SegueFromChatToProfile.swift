//
//  SegueFromChatToProfile.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/16/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class SegueFromChatToProfile: UIStoryboardSegue {
    override func perform() {
        let src = self.source as! ChatController
        let dst = self.destination as! ProfileController
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: 0, y: -src.view.frame.size.height)
        
        UIView.animate(withDuration: 1.0, animations: {
            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
            
        }) { (Finished) in
            src.present(dst, animated: false, completion: nil)
        }
    }
}
