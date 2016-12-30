//
//  ModalQuestionController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/20/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ModalQuestionController: UIViewController {
    
    var classroom: Classroom! {
        didSet {
            // Set modal info
            let question = classroom.questions[0] // Grab the most recent question
            _ = downloadImage(imageUrlString: question.imageName, completed: { image in
                self.questionImageView.image = image
            })
            self.questionNum.text = "Question \(classroom.questionNum)"
            self.questionText.text = question.question
        }
    }
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    fileprivate let questionImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    fileprivate let questionNum: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let questionText: UITextView = {
       let textView = UITextView()
        textView.font = FONT_MEDIUM_MID
        textView.textColor = UIColor.darkGray
        textView.textAlignment = .left
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = true
        textView.isEditable = false
        textView.isSelectable = false
        return textView
    }()
    
    func dismissScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissScreen))
        view.addGestureRecognizer(tapGestureRecognizer)
        view.isUserInteractionEnabled = true
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        questionText.flashScrollIndicators()
    }
    
    fileprivate func setupViews() {
        
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraintsWithFormat("V:|-128-[v0]-128-|", views: containerView)
        
        containerView.addSubview(questionImageView)
        containerView.addSubview(questionNum)
        containerView.addSubview(questionText)
        
        containerView.addConstraintsWithFormat("V:|[v0(250)]-12-[v1(20)]-3-[v2]-|", views: questionImageView, questionNum, questionText)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: questionImageView)
        containerView.addConstraintsWithFormat("H:|-12-[v0]-12-|", views: questionNum)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
    }
}
