//
//  ViewController.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var imageModels: [HXImageModel] = []
    private var images: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let itemSpacing: CGFloat = 10
        let itemWidth = (hxip_screenWidth - itemSpacing) / 3 - itemSpacing
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.sectionInset = UIEdgeInsets(top: itemSpacing, left: itemSpacing, bottom: itemSpacing, right: itemSpacing)
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        collectionView.collectionViewLayout = layout
        collectionView.hx_registerCell(cellClass: HXImageCell.self)
    }

    @IBAction func imagePickerBtnClicked(_ sender: Any) {
//        let imagePircker = HXImagePickerController(hasAlbumList: false)
        let imagePircker = HXImagePickerController()
//        imagePircker.mediaTypes = [.image]
        imagePircker.maxSelectCount = 1
        imagePircker.mainTintColor = UIColor(red: 249 / 255.0, green: 60 / 255.0, blue: 83 / 255.0, alpha: 1)
        imagePircker.hxip_delegate = self
        imagePircker.modalPresentationStyle = .fullScreen
        present(imagePircker, animated: true, completion: nil)
    }
    
}

// MARK: -  HXImagePickerControllerDelegate
extension ViewController: HXImagePickerControllerDelegate {
    
    func imagePickerControllerDidCancelSelect(_ imagePickerController: HXImagePickerController) {
        print("picker cancel")
    }
    
    func imagePickerController(_ imagePickerController: HXImagePickerController, didSelected imageModels: [HXImageModel], isOrigin: Bool) {
        self.imageModels = imageModels
        for imageModel in imageModels {
            HXLog(imageModel.assetId)
        }
    }
    
    func imagePickerController(_ imagePickerController: HXImagePickerController, didSelected images: [UIImage]) {
        self.images = images
        for image in images {
            HXLog(image.size)
        }
        collectionView.reloadData()
    }
    
}

// MARK: -  UICollectionViewDelegate, UICollectionViewDataSource
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.hx_dequeueReusableCell(indexPath: indexPath) as HXImageCell
        cell.selectBtn.isHidden = true
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}
