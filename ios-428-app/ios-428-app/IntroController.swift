//
//  IntroController.swift
//  ios-428-app
//
//  This class is fired once for a new user.
//  Created by Leonard Loo on 10/22/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class IntroController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    fileprivate let MAX_TEXTFIELD_CHARACTERS = 40
    fileprivate let MAX_TEXTVIEW_CHARACTERS = 400
    
    override func viewDidLoad() {
        self.view.backgroundColor = GRAY_UICOLOR
        scrollView.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(keepKeyboard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        self.automaticallyAdjustsScrollViewInsets = false
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterObservers()
    }
    
    // MARK: Sliders
    
    fileprivate let scrollView: UIScrollView = {
        let frame = UIScreen.main.bounds
        // Scroll view width and height set according to constraints defined in setupViews
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width - 40, height: frame.height - 100))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    fileprivate lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = self.sliderViews.count
        control.currentPage = 0
        control.tintColor = UIColor.lightGray
        control.pageIndicatorTintColor = UIColor.lightGray
        control.currentPageIndicatorTintColor = UIColor.darkGray
        return control
    }()
    
    fileprivate let slider1View: UIView = {
        let view = UIView()
        view.backgroundColor = GRAY_UICOLOR
        return view
    }()
    
    fileprivate let slider2View: UIView = {
        let view = UIView()
        view.backgroundColor = GRAY_UICOLOR
        return view
    }()
    
    fileprivate let slider3View: UIView = {
        let view = UIView()
        view.backgroundColor = GRAY_UICOLOR
        return view
    }()
    
    var sliderViews: [UIView] = []
    var frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    func changePage(sender: AnyObject) -> () {
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    // Delegate function that changes pageControl when scrollView scrolls
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
    
    fileprivate func setupViews() {
        
        sliderViews.append(slider1View)
        sliderViews.append(slider2View)
        sliderViews.append(slider3View)
        
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        
        for index in 0..<sliderViews.count {
            frame.origin.x = self.scrollView.frame.size.width * CGFloat(index)
            frame.size = self.scrollView.frame.size
            let subView = self.sliderViews[index]
            subView.frame = frame
            scrollView.addSubview(subView)
        }
        
        scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(sliderViews.count), height: self.scrollView.frame.size.height)
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: pageControl)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: scrollView)
        
        view.addConstraint(NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        view.addConstraintsWithFormat("V:[v0][v1(30)]-15-|", views: scrollView, pageControl)
        
        self.setupSlider1()
        self.setupSlider2()
        self.setupSlider3()
 
    }
    
    // MARK 1: Slider 1 to fill in Professional Info
    
    fileprivate let firstTellUsLabel: UILabel = {
       let label = UILabel()
        label.text = "Confess your profession:"
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()
    
    fileprivate func titleLabelTemplate() -> UILabel {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }
    
    fileprivate lazy var disciplineTitleLabel: UILabel = {
        let label = self.titleLabelTemplate()
        label.text = "Discipline*"
        return label
    }()
    
    fileprivate lazy var schoolTitleLabel: UILabel = {
        let label = self.titleLabelTemplate()
        label.text = "School*"
        return label
    }()
    
    fileprivate lazy var orgTitleLabel: UILabel = {
        let label = self.titleLabelTemplate()
        label.text = "Organization*"
        return label
    }()

    fileprivate func textfieldTemplate() -> UITextField {
        let textfield = UITextField()
        textfield.delegate = self
        textfield.font = FONT_MEDIUM_LARGE
        textfield.textColor = UIColor.darkGray
        textfield.borderStyle = .none
        textfield.backgroundColor = UIColor.white
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textfield.frame.height))
        textfield.leftView = paddingView
        textfield.leftViewMode = .always
        textfield.tintColor = GREEN_UICOLOR
        let editImageView = UIImageView(image: #imageLiteral(resourceName: "edit"))
        editImageView.frame = CGRect(x: 0, y: 0, width: editImageView.image!.size.width + 20.0, height: editImageView.image!.size.height)
        editImageView.contentMode = .center
        textfield.rightView = editImageView
        textfield.rightViewMode = .unlessEditing
        textfield.returnKeyType = .done
        return textfield
    }
    
    fileprivate lazy var disciplineTextField: UITextField = {
        let textfield: UITextField = self.textfieldTemplate()
        textfield.placeholder = "Your discipline or industry"
        textfield.inputView = self.pickerView
        return textfield
    }()
    
    fileprivate lazy var schoolTextField: UITextField = {
        let textfield: UITextField = self.textfieldTemplate()
        textfield.placeholder = "Your current or past school"
        return textfield
    }()
    
    fileprivate lazy var orgTextField: UITextField = {
        let textfield: UITextField = self.textfieldTemplate()
        textfield.placeholder = "Your company or club"
        return textfield
    }()
    
    fileprivate func editDisciplineIconInTextField(imageString: String) {
        if imageString.isEmpty {
            // Null choice, display empty text field
            disciplineTextField.text = ""
            return
        }
        let image = UIImage(named: imageString)?.resizeWith(width: 20.0)
        let imageView: UIImageView = UIImageView(image: image)
        let width = image == nil ? 20 : image!.size.width + 20
        let height = image == nil ? 20 : image!.size.height
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        imageView.contentMode = .center
        disciplineTextField.leftView = imageView
        disciplineTextField.leftViewMode = .always
    }
    
    fileprivate let slider1FillInNow: UILabel = {
        let label = UILabel()
        label.text = "Please fill in all three fields."
        label.font = FONT_HEAVY_SMALL
        label.textColor = RED_UICOLOR
        label.textAlignment = .center
        label.isHidden = false
        return label
    }()
    
    // MARK: Slider1 - Pickerview for discipline
    
    fileprivate lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.tintColor = GREEN_UICOLOR
        picker.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(keepPickerView))
        tap.delegate = self
        picker.addGestureRecognizer(tap)
        return picker
    }()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func keepPickerView() {
        self.view.endEditing(true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DISCIPLINE_OPTIONS.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return DISCIPLINE_OPTIONS[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        disciplineTextField.text = DISCIPLINE_OPTIONS[row]
        enableGo(yes: orgTextField.text!.characters.count > 0 && schoolTextField.text!.characters.count > 0)
        editDisciplineIconInTextField(imageString: DISCIPLINE_ICONS[row])
    }
    
    fileprivate func setupSlider1() {
        slider1View.addSubview(firstTellUsLabel)
        slider1View.addSubview(orgTitleLabel)
        slider1View.addSubview(orgTextField)
        slider1View.addSubview(schoolTitleLabel)
        slider1View.addSubview(schoolTextField)
        slider1View.addSubview(disciplineTitleLabel)
        slider1View.addSubview(disciplineTextField)
        slider1View.addSubview(slider1FillInNow)
        
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: firstTellUsLabel)
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: orgTitleLabel)
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: orgTextField)
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: schoolTitleLabel)
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: schoolTextField)
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: disciplineTitleLabel)
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: disciplineTextField)
        slider1View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: slider1FillInNow)
        
        let margin: CGFloat = max((UIScreen.main.bounds.height - 450) / 2.0, 0.0)
        
        slider1View.addConstraintsWithFormat("V:|-\(margin)-[v0(40)]-15-[v1(20)]-5-[v2(45)]-25-[v3(20)]-5-[v4(45)]-25-[v5(20)]-5-[v6(45)]-10-[v7(20)]", views: firstTellUsLabel, disciplineTitleLabel, disciplineTextField, schoolTitleLabel, schoolTextField, orgTitleLabel, orgTextField, slider1FillInNow)
    }
    
    // MARK: Slider 2 - I am working on text view
    
    fileprivate func placeholderTemplate() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.lightGray
        label.sizeToFit()
        label.isHidden = false
        return label
    }
    
    fileprivate lazy var taglinePlaceholder: UILabel = {
        let label: UILabel = self.placeholderTemplate()
        label.text = "At 4:28pm, you can find me..."
        return label
    }()
    
    fileprivate func textViewTemplate() -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.textColor = UIColor.darkGray
        textView.backgroundColor = UIColor.white
        textView.delegate = self
        textView.textAlignment = .left
        textView.tintColor = GREEN_UICOLOR
        return textView
    }
    
    fileprivate lazy var taglineTextView: UITextView = {
        let textView: UITextView = self.textViewTemplate()
        return textView
    }()
    
    fileprivate lazy var taglineLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_LARGE
        label.textColor = UIColor.black
        label.textAlignment = .left
        label.text = "What I do at 4:28pm:"
        return label
    }()
    
    fileprivate func countLabelTemplate() -> PaddingLabel {
        let label = PaddingLabel()
        label.font = FONT_HEAVY_SMALL
        label.textColor = UIColor.gray
        label.textAlignment = .right
        label.backgroundColor = UIColor.white
        return label
    }
    
    fileprivate lazy var taglineCountLabel: UILabel = {
        let label: UILabel = self.countLabelTemplate()
        label.text = "\(self.MAX_TEXTVIEW_CHARACTERS)"
        return label
    }()
    
    fileprivate let taglineFillInLater: UILabel = {
        let label = UILabel()
        label.text = "You may fill this in later."
        label.font = FONT_HEAVY_SMALL
        label.textColor = GREEN_UICOLOR
        label.textAlignment = .center
        return label
    }()
    
    fileprivate func setupSlider2() {
        slider2View.addSubview(taglineLabel)
        slider2View.addSubview(taglineTextView)
        slider2View.addSubview(taglinePlaceholder)
        slider2View.addSubview(taglineCountLabel)
        slider2View.addSubview(taglineFillInLater)
        
        slider2View.addConstraintsWithFormat("H:|-8-[v0]", views: taglineLabel)
        slider2View.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: taglineTextView)
        slider2View.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: taglineCountLabel)
        slider2View.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: taglineFillInLater)
        
        let margin: CGFloat = max((UIScreen.main.bounds.height - 350) / 2.0, 0.0)
        
        // Each text view is 0.3 * screenSize
        let textviewHeight = 0.28 * UIScreen.main.bounds.height
        slider2View.addConstraintsWithFormat("V:|-\(margin)-[v0(20)]-8-[v1(\(textviewHeight))][v2(20)]-8-[v3(20)]", views: taglineLabel, taglineTextView, taglineCountLabel, taglineFillInLater)
        
        // Align placeholders to text views
        slider2View.addConstraintsWithFormat("H:|-13-[v0]-13-|", views: taglinePlaceholder)
        slider2View.addConstraintsWithFormat("V:[v0(100)]", views: taglinePlaceholder)
        
        slider2View.addConstraint(NSLayoutConstraint(item: taglinePlaceholder, attribute: .top, relatedBy: .equal, toItem: taglineLabel, attribute: .bottom, multiplier: 1.0, constant: -24.0))
    }
    
    // MARK: Slider 3 - Segue to main app
    
    fileprivate let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_XLARGE
        label.textColor = UIColor.darkGray
        label.text = "One new a classroom a week, and one new question a day at"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let _428Label: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_XXLARGE
        label.textColor = GREEN_UICOLOR
        label.text = "4:28 pm"
        label.textAlignment = .center
        return label
    }()
    
    fileprivate lazy var goButton: UIButton = {
        let button = UIButton()
        button.setTitle("LET'S GO!", for: .normal)
        button.titleLabel?.font = FONT_HEAVY_XLARGE
        button.setTitleColor(UIColor.white, for: .normal)
        button.setBackgroundColor(color: GREEN_UICOLOR, forState: .normal)
        button.setBackgroundColor(color: GREEN_UICOLOR.withAlphaComponent(0.6), forState: .highlighted)
        button.layer.cornerRadius = 4.0
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(goIntoApp), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    fileprivate let cautionText: UILabel = {
        let label = UILabel()
        label.font = FONT_HEAVY_MID
        label.textColor = RED_UICOLOR
        label.text = "Please fill in all profession fields."
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.isHidden = false
        return label
    }()
    
    // Function that lets user proceed to the main app
    fileprivate func enableGo(yes: Bool) {
        goButton.isEnabled = yes
        cautionText.isHidden = yes
        slider1FillInNow.isHidden = yes
    }
    
    // Enter main app after updating user profile data
    func goIntoApp() {
        // Set environment variable, then dismiss to Login
        DataService.ds.updateUserFields(discipline: disciplineTextField.text, school: schoolTextField.text, organization: orgTextField.text, tagline: taglineTextView.text, completed: { (isSuccess) in
            if !isSuccess {
                showErrorAlert(vc: self, title: "Unable to proceed", message: "We apologize. We seem to be unable to log you in at this time. Please try again later.")
            } else {
                log.info("Going into the app")
                justFinishedIntro = true
                setHasToFillInfo(hasToFill: false)
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    fileprivate func setupSlider3() {
        slider3View.addSubview(descriptionLabel)
        slider3View.addSubview(_428Label)
        slider3View.addSubview(goButton)
        slider3View.addSubview(cautionText)
        
        slider3View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: descriptionLabel)
        slider3View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: _428Label)
        slider3View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: goButton)
        slider3View.addConstraintsWithFormat("H:|-15-[v0]-15-|", views: cautionText)
        
        let margin: CGFloat = max((UIScreen.main.bounds.height - 300) / 2.0, 0.0)
        slider3View.addConstraintsWithFormat("V:|-\(margin)-[v0(80)]-8-[v1(40)]-8-[v2(40)]-8-[v3(30)]", views: descriptionLabel, _428Label, goButton, cautionText)
    }
    
    // MARK: Text view
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == taglineTextView {
            self.taglinePlaceholder.isHidden = !textView.text.isEmpty
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        
        if numberOfChars <= MAX_TEXTVIEW_CHARACTERS {
            if textView == taglineTextView {
                taglineCountLabel.text = "\(max(MAX_TEXTVIEW_CHARACTERS - numberOfChars, 0))"
            }
        }
        return numberOfChars < MAX_TEXTVIEW_CHARACTERS
    }
    
    // MARK: Text field

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField == disciplineTextField {
            return false
        }
        let nsString = textField.text as NSString?
        let newString = nsString?.replacingCharacters(in: range, with: string)
        if let newLength = newString?.characters.count {
            if textField == orgTextField {
                enableGo(yes: newLength > 0 && schoolTextField.text!.characters.count > 0 && disciplineTextField.text!.characters.count > 0)
            } else if textField == schoolTextField {
                enableGo(yes: newLength > 0 && orgTextField.text!.characters.count > 0 && disciplineTextField.text!.characters.count > 0)
            }
            return newLength <= MAX_TEXTFIELD_CHARACTERS
        }
        
        enableGo(yes: false)
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // MARK: Keep keyboard
    
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func getActiveTextFieldFrame() -> CGRect? {
        var chosenTextField: UITextField?
        if self.orgTextField.isFirstResponder {
            chosenTextField = self.orgTextField
        }
        if self.schoolTextField.isFirstResponder {
            chosenTextField = schoolTextField
        }
        if self.disciplineTextField.isFirstResponder {
            chosenTextField = disciplineTextField
        }
        if chosenTextField != nil {
            return slider1View.convert(chosenTextField!.frame, to: view)
        }
        return nil
    }
    
    fileprivate func getActiveTextViewFrame() -> CGRect? {
        if self.taglineTextView.isFirstResponder {
            return slider2View.convert(taglineTextView.frame, to: view)
        }
        return nil
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            let isKeyboardShowing = notification.name != Notification.Name.UIKeyboardWillHide
            let keyboardViewEndFrame = view.convert(keyboardFrame, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height
            
            let activeTextFieldFrame = getActiveTextFieldFrame()
            let activeTextViewFrame = getActiveTextViewFrame()
            if activeTextFieldFrame == nil && activeTextViewFrame == nil {
                return
            }
            
            var bottomOfView: CGFloat = 0.0
            if activeTextFieldFrame != nil {
                bottomOfView = activeTextFieldFrame!.maxY
            } else if activeTextViewFrame != nil {
                bottomOfView = activeTextViewFrame!.maxY + 60
            }
            let topOfKeyboard = self.view.bounds.maxY - keyboardHeight
            UIView.animate(withDuration: animationDuration, animations: {
                if isKeyboardShowing && bottomOfView >= topOfKeyboard {
                    let distanceShifted = min(keyboardHeight, abs(bottomOfView - topOfKeyboard))
                    self.view.frame.origin.y = -distanceShifted
                } else {
                    self.view.frame.origin.y = 0
                    self.scrollView.frame = CGRect(x: 20.0, y: 28.0, width: self.frame.width, height: self.frame.height + 27.0)
                }
            })
        }
    }
    
    func keepKeyboard() {
        self.view.endEditing(true)
    }
    
}
