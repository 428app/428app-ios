//
//  HorizontalScrollCell.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/17/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class HorizontalScrollCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "iconImageCell"
    
    fileprivate var iconImageNames = [String]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
        self.internalCollectionView.delegate = self
        self.internalCollectionView.dataSource = self
        self.internalCollectionView.register(IconImageCell.self, forCellWithReuseIdentifier: CELL_ID)
        self.internalCollectionView.showsHorizontalScrollIndicator = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate let internalCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.white
        return collectionView
    }()
    
    fileprivate func setupViews() {
        backgroundColor = UIColor.white
        addSubview(internalCollectionView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[v0]-8-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": internalCollectionView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": internalCollectionView]))
    }
    
    func configureCell(icons: [String]) {
        self.iconImageNames = icons
        self.internalCollectionView.reloadData()
    }
    
    // MARK: Horizontal Collection view housed inside this cell
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return iconImageNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let iconImageName = iconImageNames[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! IconImageCell
        cell.assignImage(imageName: iconImageName)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: ProfileController.ICON_SIZE, height: frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let iconImageName = iconImageNames[indexPath.row]
        // Send notification to ProfileController to launch modal about this icon image
        NotificationCenter.default.post(name: NOTIF_PROFILEICONTAPPED, object: nil, userInfo: ["iconImageName": iconImageName])
    }
}

// Internal cell for icon images in horizontal collection view
class IconImageCell: UICollectionViewCell {
    
    fileprivate var iconImageView: UIImageView = {
       let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: ProfileController.ICON_SIZE, height: ProfileController.ICON_SIZE))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.tintColor = GREEN_UICOLOR // Applies to template images only
        imageView.backgroundColor = UIColor.white
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        backgroundColor = UIColor.white
        addSubview(iconImageView)
    }
    
    func assignImage(imageName: String) {
        iconImageView.image = UIImage(named: imageName)
    }
    
}
