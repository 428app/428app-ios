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
    
    let CORNER_RADIUS: CGFloat = 15.0
    let HORIZONTAL_MARGIN: CGFloat = 28.0
    let VERTICAL_MARGIN: CGFloat = 200.0
    
    var classroom: Classroom! {
        didSet {
            // Set modal info
            let question = classroom.questions[0] // Grab the most recent question
            _ = downloadImage(imageUrlString: question.imageName, completed: { image in
                self.questionImageView.image = image
            })
            self.questionText.text = question.question
        }
    }
    
    fileprivate lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = GREEN_UICOLOR
        view.layer.cornerRadius = self.CORNER_RADIUS
        return view
    }()
    
    fileprivate lazy var questionImageView: UIImageView = {
        let frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width - self.HORIZONTAL_MARGIN * 2, height: 150)
       let imageView = UIImageView(frame: frame)
        imageView.contentMode = .scaleAspectFill
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: imageView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: self.CORNER_RADIUS, height: self.CORNER_RADIUS)).cgPath
        maskLayer.path = path
        imageView.layer.mask = maskLayer
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
        view.addConstraintsWithFormat("H:|-\(self.HORIZONTAL_MARGIN)-[v0]-\(self.HORIZONTAL_MARGIN)-|", views: containerView)
        view.addConstraintsWithFormat("V:|-\(self.VERTICAL_MARGIN)-[v0]-\(self.VERTICAL_MARGIN)-|", views: containerView)
        
        containerView.addSubview(questionImageView)
        containerView.addSubview(questionText)
        
        containerView.addConstraintsWithFormat("V:|[v0(150)]-3-[v1]-8-|", views: questionImageView, questionText)
        containerView.addConstraintsWithFormat("H:|[v0]|", views: questionImageView)
        containerView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: questionText)
    }
    
}
