//
//  ClassmatesController.swift
//  ios-428-app
//
//  Created by Leonard Loo on 12/30/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import UIKit

class ClassmatesController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let CELL_ID = "classmatesProfileCell"
    
    open var classmates: [Profile]!
    
    let interactor = Interactor() // Used for transitioning to and from ProfileController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Classmates"
        self.view.backgroundColor = GREEN_UICOLOR
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: GREEN_UICOLOR), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.tabBarController?.tabBar.isHidden = false
    }
    
    fileprivate func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = GREEN_UICOLOR
        collectionView?.bounces = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.register(ClassmatesProfileCell.self, forCellWithReuseIdentifier: CELL_ID)
        collectionView?.contentInset.top = 20.0
    }
    // MARK: Collection view
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.classmates.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! ClassmatesProfileCell
        let classmate = self.classmates[indexPath.item]
        cell.configureCell(profileObj: classmate)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 2 cells per row
        return CGSize(width: UIScreen.main.bounds.width / 2.0, height: 168.0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let classmate = self.classmates[indexPath.item]
        let controller = ProfileController()
        controller.transitioningDelegate = self
        controller.interactor = interactor
        controller.profile = classmate
        controller.modalTransitionStyle = .coverVertical
        controller.modalPresentationStyle = .overFullScreen
        self.present(controller, animated: true, completion: nil)
    }
    
}
