//
//  HXPreviewThumbCell.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/3/14.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class HXPreviewThumbCell: UICollectionViewCell {
    
    ///  数据源
    var imageModel: HXImageModel? {
        didSet {
            guard let imageModel = imageModel else { return }
            imageView.image = imageModel.thumbImage
            imageModel.requestThumbImage { [weak self] (model, thumbImage) in
                guard let `self` = self else { return }
                self.imageView.image = thumbImage
            }
            editedIconImageView.isHidden = !imageModel.isEdited
        }
    }
    
    // MARK: -  懒加载
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    lazy var editedIconImageView: UIImageView = {
        let editedIconImageView = UIImageView()
        editedIconImageView.image = UIImage(named: "HXImagePickerController.bundle/hxip_edited")
        editedIconImageView.isHidden = true
        return editedIconImageView
    }()
    
    // MARK: -  Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(editedIconImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        editedIconImageView.frame = CGRect(x: 8, y: bounds.height - 20, width: 17, height: 13)
    }
    
}
