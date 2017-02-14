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
            self.questionText.text = question.question
            self.questionText.text = "Why is Jet lag worse after you've traveled east? Why is Jet lag worse after you've traveled east? Why is Jet lag worse after you've traveled east? Why is Jet lag worse after you've traveled east? Why is Jet lag worse after you've traveled east? Why is Jet lag worse after you've traveled east? Why is Jet lag worse after you've traveled east?"
        }
    }
    
    fileprivate let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = GREEN_UICOLOR
        view.layer.cornerRadius = 15.0
        return view
    }()
    
    fileprivate let questionImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
//        imageView.layer.cornerRadius = 15.0 
        return imageView
    }()
    
    fileprivate let questionText: UITextView = {
       let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.backgroundColor = GREEN_UICOLOR
        textView.textColor = UIColor.white
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
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
    }
    
    fileprivate func setupViews() {
        view.addSubview(containerView)
        view.addConstraintsWithFormat("H:|-28-[v0]-28-|", views: containerView)
        view.addConstraintsWithFormat("V:|-200-[v0]-200-|", views: containerView)
        
        containerView.addSubview(questionImageView)
        containerView.addSubview(questionText)
        
        containerView.addConstraintsWithFormat("V:|[v0(150)]-3-[v1]-8-|", views: questionImageView, questionText)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: questionImageView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
    }
    
}
