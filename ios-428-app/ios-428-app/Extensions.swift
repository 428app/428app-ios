//
//  Extensions.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/11/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        _ = _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    func addAndGetConstraintsWithFormat(_ format: String, views: UIView...) -> [NSLayoutConstraint] {
        return _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    fileprivate func _addAndGetConstraintsWithFormat(_ format: String, views: [UIView]) -> [NSLayoutConstraint] {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        let constraints_ = NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary)
        addConstraints(constraints_)
        return constraints_
    }
}

extension UIViewController {
    // Returns the scroll view and container view
    func setupScrollView() -> [UIView] {
        let scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        let containerView = UIView()
        scrollView.addSubview(containerView)
        view.addSubview(scrollView)
        view.addConstraintsWithFormat("H:|[v0]|", views: scrollView)
        view.addConstraintsWithFormat("V:|[v0]|", views: scrollView)
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0))
        scrollView.addConstraintsWithFormat("H:|[v0]|", views: containerView)
        scrollView.addConstraintsWithFormat("V:|[v0]|", views: containerView)
        return [scrollView, containerView]
    }
}

public extension UIImage {
    // Create a UIImage from color
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    // Create a circular image
    var circle: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2.0
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    // Tweak the alpha of this image
    func alpha(value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func maskWithColor(color: UIColor) -> UIImage? {
        
        let maskImage = self.cgImage
        let width = self.size.width
        let height = self.size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let bitmapContext = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) //needs rawValue of bitmapInfo
        
        bitmapContext!.clip(to: bounds, mask: maskImage!)
        bitmapContext!.setFillColor(color.cgColor)
        bitmapContext!.fill(bounds)
        
        //is it nil?
        if let cImage = bitmapContext!.makeImage() {
            let coloredImage = UIImage(cgImage: cImage)
            return coloredImage
            
        } else {
            return nil
        } 
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
}
