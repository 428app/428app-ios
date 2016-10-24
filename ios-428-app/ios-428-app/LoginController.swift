//
//  LoginController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/20/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit
import CoreLocation

class LoginController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate {
    
    fileprivate let MINIMAL_FRIEND_COUNT = 50 // Minimal number of friends required to authenticate 'real' user
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GRAY_UICOLOR
        scrollView.delegate = self
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if justFinishedIntro {
            justFinishedIntro = false
            let controller = CustomTabBarController()
            controller.modalTransitionStyle = .coverVertical
            self.present(controller, animated: true, completion: nil)
        }
        super.viewWillAppear(animated)
        // Scroll back to first 
        pageControl.currentPage = 0
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let _ = FBSDKAccessToken.current(), let user = FIRAuth.auth()?.currentUser {
            STORED_UID = user.providerData[0].uid
            self.startLocationManager()
            let controller = CustomTabBarController()
            controller.modalTransitionStyle = .coverVertical
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    fileprivate lazy var loginButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = FONT_MEDIUM_LARGE
        button.setTitle("Log in with Facebook", for: .normal)
        button.setBackgroundColor(color: FB_BLUE_UICOLOR, forState: .normal)
        button.setBackgroundColor(color: FB_BLUE_UICOLOR.withAlphaComponent(0.8), forState: .highlighted)
        button.addTarget(self, action: #selector(fbLogin), for: .touchUpInside)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 3.0
        button.clipsToBounds = true
        return button
    }()
    
    // MARK: Location manager
    
    fileprivate var locationManager = CLLocationManager()

    fileprivate func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            // Get location once, once location obtained, stop location manager
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        log.error(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Last location captured must have positive accuracy and not captured more than 10 seconds ago
        if let loc = locations.last, loc.horizontalAccuracy > 0.0, loc.timestamp.timeIntervalSinceNow > -10.0 {
            let lat = loc.coordinate.latitude
            let lon = loc.coordinate.longitude
            // Update user's location, and stops location manager
            if STORED_UID == "" {
                log.error("Stored uid not set yet")
                return
            }
            DataService.ds.updateUserLocation(fbid: STORED_UID, lat: lat, lon: lon, completed: { (isSuccess) in
                if isSuccess {
                    self.locationManager.stopUpdatingLocation()
                } else {
                    log.error("There was an error in getting user's location")
                }
            })
        }
    }
    
    // MARK: Server login
    
    // Triggered on clicking Facebook Login button
    func fbLogin() {
        let facebookLogin = FBSDKLoginManager()
        // TODO: Submit app review to facebook to get permission for user_birthday
        facebookLogin.logIn(withReadPermissions: ["public_profile", "user_friends", "user_birthday"], from: self) { (facebookResult, facebookError) in
            
            if facebookError != nil || facebookResult == nil {
                log.error("Facebook login failed. Error \(facebookError)")
                return
            } else if facebookResult!.isCancelled {
                log.warning("Facebook login was cancelled.")
                return
            } else {
                showLoader(message: "Syncing you with Facebook...")
                // Launch FB graph search to get birthday, higher resolution picture, and friends
                let fbRequest = FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields": "birthday,picture.width(960).height(960),friends"])
                let connection = FBSDKGraphRequestConnection()
                connection.add(fbRequest, completionHandler: { (conn, fbResult, error) in
                    
                    if error != nil || fbResult == nil {
                        log.error("Could not fetch user details from FB graph")
                        showErrorAlert(vc: self, title: "Could not sign in", message: "There was a problem syncing with Facebook. Please check back again later.")
                        return
                    } else {
                        
                        // Chaining to get friend count, picture url and birthday from graph request result
                        guard let result = fbResult as? [String: Any], let friendCount = (result as NSDictionary).value(forKeyPath: "friends.summary.total_count") as? Int, let pictureUrl = (result as NSDictionary).value(forKeyPath: "picture.data.url") as? String, let birthdayString = result["birthday"] as? String else {
                            log.error("Could not fetch user details from FB graph")
                            showErrorAlert(vc: self, title: "Could not sign in", message: "There was a problem syncing with Facebook. Please check back again later.")
                            return
                        }
                        
                        // Make sure user at least has a certain number of friends, if not flag fake account
                        if friendCount < self.MINIMAL_FRIEND_COUNT {
                            log.error("User does not have enough FB friends")
                            showErrorAlert(vc: self, title: "Oops", message: "Hmm... we suspect you're not using your genuine Facebook account. Kindly login using your real account. If you feel that that's a problem, contact us.")
                            return
                        }
                        
                        // Real user ascertained. Continue to login user to Firebase
                        self.loginToFirebase(birthdayString: birthdayString, pictureUrl: pictureUrl)
                    }
                })
                connection.start()
            }
        }
    }
    
    fileprivate func loginToFirebase(birthdayString: String, pictureUrl: String) {
        let accessToken: String = FBSDKAccessToken.current().tokenString
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken)
        showLoader(message: "Logging you in...")
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            
            if error != nil || user == nil || user!.providerData[0].displayName == nil {
                log.error("Auth with Firebase failed")
                showErrorAlert(vc: self, title: "Could not sign in", message: "There was a problem signing in. We apologize. Please try again later.")
                return
            }
            
            let fbid = user!.providerData[0].uid // Use FBID as the key for users
            let displayName = user!.providerData[0].displayName!
            
            // Get timezone
            let secondsFromGMT: Double = Double(NSTimeZone.local.secondsFromGMT())
            let timezone: Double = secondsFromGMT*1.0 / (60.0*60.0)
            
            // Create/Update Firebase user with details
            DataService.ds.loginFirebaseUser(fbid: fbid, name: displayName, birthday: birthdayString, pictureUrl: pictureUrl, timezone: timezone, completed: { (isSuccess, isFirstTimeUser) in
                if !isSuccess {
                    log.error("Login to Firebase failed")
                    showErrorAlert(vc: self, title: "Could not sign in", message: "There was a problem signing in. We apologize. Please try again later.")
                    return
                }

                hideLoader()
                STORED_UID = fbid
                // Successfully updated user info in DB, get user's location, and logs user in!
                self.startLocationManager()
                let controller = isFirstTimeUser ? IntroController() : CustomTabBarController()
                controller.modalTransitionStyle = .coverVertical
                self.present(controller, animated: true, completion: nil)
            })
        })

    }
    
    // MARK: Frontend
    
    fileprivate let warningLabel: UILabel = {
        let label = UILabel()
        label.font = FONT_MEDIUM_SMALL
        label.textColor = UIColor.darkGray
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        paragraphStyle.alignment = .center
        let str1 = NSMutableAttributedString(string: "By continuing, you agree to our ", attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        let str2 = NSMutableAttributedString(string: "Terms of Service", attributes: [NSFontAttributeName: FONT_HEAVY_SMALL])
        let str3 = NSMutableAttributedString(string: " and ")
        let str4 = NSMutableAttributedString(string: "Privacy Policy", attributes: [NSFontAttributeName: FONT_HEAVY_SMALL])
        str1.append(str2)
        str1.append(str3)
        str1.append(str4)
        label.attributedText = str1
        
        return label
    }()
    
    fileprivate let fbDisclaimerIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "info")
        return imageView
    }()
    
    fileprivate let fbDisclaimerLabel: UILabel = {
       let label = UILabel()
        label.font = FONT_MEDIUM_SMALL
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = "We do not post anything to Facebook."
        return label
    }()
    
    // MARK: Sliders
    
    fileprivate let scrollView: UIScrollView = {
        let frame = UIScreen.main.bounds
        // Scroll view width and height set according to constraints defined in setupViews
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width - 40, height: frame.height - 205))
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
    
    fileprivate let slider1View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "LoginSlider1")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    fileprivate let slider2View: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "LoginSlider2")
        imageView.backgroundColor = GRAY_UICOLOR
        return imageView
    }()
    
    var sliderViews: [UIImageView] = []
    var colors: [UIColor] = [UIColor.red, UIColor.blue]
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
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(warningLabel)
        view.addSubview(loginButton)
        
        for index in 0..<2 {
            frame.origin.x = self.scrollView.frame.size.width * CGFloat(index)
            frame.size = self.scrollView.frame.size
            let subView = self.sliderViews[index]
            subView.frame = frame
            self.scrollView.addSubview(subView)
        }
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(sliderViews.count), height: self.scrollView.frame.size.height)
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: pageControl)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: scrollView)

        let disclaimerContainer = UIView()
        disclaimerContainer.addSubview(fbDisclaimerIcon)
        disclaimerContainer.addSubview(fbDisclaimerLabel)
        disclaimerContainer.translatesAutoresizingMaskIntoConstraints = false
        disclaimerContainer.addConstraintsWithFormat("H:|[v0(14)]-4-[v1]|", views: fbDisclaimerIcon, fbDisclaimerLabel)
        disclaimerContainer.addConstraintsWithFormat("V:|[v0(14)]", views: fbDisclaimerIcon)
        disclaimerContainer.addConstraintsWithFormat("V:|-1-[v0(14)]|", views: fbDisclaimerLabel)
        view.addSubview(disclaimerContainer)
        view.addConstraint(NSLayoutConstraint(item: disclaimerContainer, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        
        view.addConstraint(NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 8.0))
        view.addConstraintsWithFormat("V:[v0][v1(30)]-2-[v2(45)]-8-[v3(45)]-15-[v4]-15-|", views: scrollView, pageControl, warningLabel, loginButton, disclaimerContainer)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: warningLabel)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: loginButton)
    }
}
