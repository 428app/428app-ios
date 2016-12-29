//
//  WebviewController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/28/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class WebviewController: UIViewController, UIWebViewDelegate {
    
    open var urlString: String! // Url string set in SettingsController, which calls this controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.extendedLayoutIncludesOpaqueBars = false
        self.setupViews()
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupToolbar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    // MARK: Web view delegate functions
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        log.warning("Web view stopped loading")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        viewForFailedLoad()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        switch navigationType {
        case .linkClicked:
            webView.loadRequest(request)
            return false
        default:
            return true
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        log.info("Web view started loading")
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        viewForSuccessfulLoad()
        log.info("Web view finished loading")
        // Set back and forward button accordingly
        forward.isEnabled = webView.canGoForward
        backward.isEnabled = webView.canGoBack
    }
    
    // MARK: Toolbar with actions
    
    let forward = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(WebviewController.goForward))
    let backward = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(WebviewController.goBack))
    
    fileprivate func setupToolbar() {
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barTintColor = GREEN_UICOLOR
        self.navigationController?.toolbar.tintColor = UIColor.white
        var items = [UIBarButtonItem]()
        
        backward.isEnabled = false
        forward.isEnabled = false
        
        items.append(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.doRefresh)))
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        items.append(backward)
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        fixedSpace.width = 30.0
        items.append(fixedSpace)
        items.append(forward)
        
        self.navigationController?.toolbar.setItems(items, animated: false)
    }
    
    func doRefresh() {
        webView.reload()
    }
    
    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }
    
    // MARK: Setup views
    
    fileprivate func viewForSuccessfulLoad() {
        noLoadImage.isHidden = true
        noLoadLbl.isHidden = true
        webView.isHidden = false
    }
    
    fileprivate func viewForFailedLoad() {
        noLoadImage.isHidden = false
        noLoadLbl.isHidden = false
        webView.isHidden = true
    }
    
    fileprivate lazy var webView: UIWebView = {
        let view = UIWebView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.delegate = self
        view.isOpaque = false
        view.backgroundColor = UIColor.clear
        view.isHidden = false
        return view
    }()
    
    fileprivate let noLoadImage: UIImageView = {
        let img = #imageLiteral(resourceName: "brokenlink")
        let imageView = UIImageView(image: img)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    fileprivate let noLoadLbl: UILabel = {
        let label = UILabel()
        label.text = "Oops, something went wrong."
        label.font = FONT_HEAVY_MID
        label.textColor = UIColor.darkGray
        label.isHidden = true
        label.textAlignment = .center
        return label
    }()
    
    fileprivate func setupViews() {
        self.view.addSubview(webView)
        
        let centralizedView = UIView()
        centralizedView.addSubview(noLoadImage)
        centralizedView.addSubview(noLoadLbl)
        centralizedView.addConstraintsWithFormat("H:[v0(60)]", views: noLoadImage)
        centralizedView.addConstraint(NSLayoutConstraint(item: noLoadImage, attribute: .centerX, relatedBy: .equal, toItem: centralizedView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        centralizedView.addConstraintsWithFormat("H:|-8-[v0]-8-|", views: noLoadLbl)
        centralizedView.addConstraintsWithFormat("V:|-8-[v0(60)]-8-[v1(30)]-8-|", views: noLoadImage, noLoadLbl)
        
        self.view.addSubview(centralizedView)
        
        self.view.addConstraint(NSLayoutConstraint(item: centralizedView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        self.view.addConstraintsWithFormat("H:|[v0]|", views: centralizedView)
    }
    
    
}
